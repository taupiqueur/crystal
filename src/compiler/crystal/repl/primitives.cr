require "./compiler"

class Crystal::Repl::Compiler
  private def visit_primitive(node, body)
    obj = node.obj

    case body.name
    when "unchecked_convert", "convert"
      # TODO: let convert raise on error
      primitive_unchecked_convert(node, body)
    when "binary"
      primitive_binary(node, body)
    when "pointer_new"
      accept_call_members(node)
      return false unless @wants_value

      pointer_new(node: node)
    when "pointer_malloc"
      discard_value(obj) if obj
      request_value(node.args.first)

      scope_type = ((obj.try &.type) || scope).instance_type

      pointer_instance_type = scope_type.instance_type.as(PointerInstanceType)
      element_type = pointer_instance_type.element_type
      element_size = inner_sizeof_type(element_type)

      pointer_malloc(element_size, node: node)
      pop(aligned_sizeof_type(scope_type), node: nil) unless @wants_value
    when "pointer_realloc"
      obj ? request_value(obj) : put_self(node: node)
      request_value(node.args.first)

      scope_type = (obj.try &.type) || scope

      pointer_instance_type = scope_type.instance_type.as(PointerInstanceType)
      element_type = pointer_instance_type.element_type
      element_size = inner_sizeof_type(element_type)

      pointer_realloc(element_size, node: node)
      pop(aligned_sizeof_type(scope_type), node: nil) unless @wants_value
    when "pointer_set"
      # Accept in reverse order so that it's easier for the interpreter
      arg = node.args.first
      request_value(arg)
      dup(aligned_sizeof_type(arg), node: nil) if @wants_value

      request_value(obj.not_nil!)
      pointer_set(inner_sizeof_type(node.args.first), node: node)
    when "pointer_get"
      accept_call_members(node)
      return unless @wants_value

      pointer_get(inner_sizeof_type(obj.not_nil!.type.as(PointerInstanceType).element_type), node: node)
    when "pointer_address"
      accept_call_members(node)
      return unless @wants_value

      pointer_address(node: node)
    when "pointer_diff"
      accept_call_members(node)
      return unless @wants_value

      pointer_diff(inner_sizeof_type(obj.not_nil!.type.as(PointerInstanceType).element_type), node: node)
    when "pointer_add"
      accept_call_members(node)
      return unless @wants_value

      pointer_add(inner_sizeof_type(obj.not_nil!.type.as(PointerInstanceType).element_type), node: node)
    when "class"
      return unless @wants_value

      put_type obj.not_nil!.type, node: node
    when "object_crystal_type_id"
      type =
        if obj
          discard_value(obj)
          obj.type
        else
          scope
        end

      return unless @wants_value

      put_i32 type_id(type), node: node
    when "allocate"
      type =
        if obj
          discard_value(obj)
          obj.type.instance_type
        else
          scope.instance_type
        end

      return unless @wants_value

      if type.struct?
        push_zeros(aligned_instance_sizeof_type(type), node: node)
      else
        allocate_class(aligned_instance_sizeof_type(type), type_id(type), node: node)
      end
    when "tuple_indexer_known_index"
      obj = obj.not_nil!
      obj.accept self

      type = obj.type
      case type
      when TupleInstanceType
        index = body.as(TupleIndexer).index
        case index
        when Int32
          element_type = type.tuple_types[index]
          offset = @context.offset_of(type, index)
          tuple_indexer_known_index(aligned_sizeof_type(type), offset, inner_sizeof_type(element_type), node: node)
        else
          node.raise "BUG: missing handling of primitive #{body.name} with range"
        end
      when NamedTupleInstanceType
        index = body.as(TupleIndexer).index
        case index
        when Int32
          entry = type.entries[index]
          offset = @context.offset_of(type, index)
          tuple_indexer_known_index(aligned_sizeof_type(type), offset, inner_sizeof_type(entry.type), node: node)
        else
          node.raise "BUG: missing handling of primitive #{body.name} with range"
        end
      else
        node.raise "BUG: missing handling of primitive #{body.name} for #{type}"
      end
    when "repl_call_stack_unwind"
      repl_call_stack_unwind(node: node)
    when "repl_raise_without_backtrace"
      repl_raise_without_backtrace(node: node)
    when "repl_intrinsics_memcpy"
      accept_call_args(node)
      repl_intrinsics_memcpy(node: node)
    when "repl_intrinsics_memmove"
      accept_call_args(node)
      repl_intrinsics_memmove(node: node)
    when "repl_intrinsics_memset"
      accept_call_args(node)
      repl_intrinsics_memset(node: node)
    when "repl_intrinsics_debugtrap"
      repl_intrinsics_debugtrap(node: node)
    when "repl_ceil_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :ceil, node: node
    when "repl_ceil_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :ceil, node: node
    when "repl_cos_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :cos, node: node
    when "repl_cos_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :cos, node: node
    when "repl_exp_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :exp, node: node
    when "repl_exp_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :exp, node: node
    when "repl_exp2_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :exp2, node: node
    when "repl_exp2_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :exp2, node: node
    when "repl_floor_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :floor, node: node
    when "repl_floor_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :floor, node: node
    when "repl_log_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :log, node: node
    when "repl_log_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :log, node: node
    when "repl_log2_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :log2, node: node
    when "repl_log2_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :log2, node: node
    when "repl_log10_f32"
      accept_call_args(node)
      repl_proc_f32_f32 :log10, node: node
    when "repl_log10_f64"
      accept_call_args(node)
      repl_proc_f64_f64 :log10, node: node
    else
      node.raise "BUG: missing handling of primitive #{body.name}"
    end
  end

  private def accept_call_args(node : Call)
    node.args.each { |arg| request_value(arg) }
    node.named_args.try &.each { |arg| request_value(arg.value) }
  end

  private def primitive_unchecked_convert(node : ASTNode, body : Primitive)
    obj = node.obj

    return false if !obj && !@wants_value

    obj_type =
      if obj
        obj.accept self
        obj.type
      else
        put_self(node: node)
        scope
      end

    return false unless @wants_value

    target_type = body.type

    primitive_unchecked_convert(node, obj_type, target_type)
  end

  private def primitive_unchecked_convert(node : ASTNode, from_type : IntegerType | FloatType, to_type : IntegerType | FloatType)
    from_kind = integer_or_float_kind(from_type)
    to_kind = integer_or_float_kind(to_type)

    unless from_kind && to_kind
      node.raise "BUG: missing handling of unchecked_convert for #{from_type} (#{node.name})"
    end

    primitive_unchecked_convert(node, from_kind, to_kind)
  end

  private def primitive_unchecked_convert(node : ASTNode, from_type : CharType, to_type : IntegerType)
    # This is Char#ord
    nop
  end

  private def primitive_unchecked_convert(node : ASTNode, from_type : IntegerType, to_type : CharType)
    primitive_unchecked_convert(node, from_type, @context.program.int32)
  end

  private def primitive_unchecked_convert(node : ASTNode, from_type : Type, to_type : Type)
    node.raise "BUG: missing handling of unchecked_convert from #{from_type} to #{to_type}"
  end

  private def primitive_unchecked_convert(node : ASTNode, from_kind : Symbol, to_kind : Symbol)
    to_kind =
      case to_kind
      when :u8  then :i8
      when :u16 then :i16
      when :u32 then :i32
      when :u64 then :i64
      else           to_kind
      end

    # Most of these are nop because we align the stack to 64 bits,
    # so numbers are already converted to 64 bits
    case {from_kind, to_kind}
    when {:i8, :i8}   then nop
    when {:i8, :i16}  then sign_extend(7, node: node)
    when {:i8, :i32}  then sign_extend(7, node: node)
    when {:i8, :i64}  then sign_extend(7, node: node)
    when {:i8, :f32}  then i8_to_f32(node: node)
    when {:i8, :f64}  then i8_to_f64(node: node)
    when {:u8, :i8}   then zero_extend(7, node: node)
    when {:u8, :i16}  then zero_extend(7, node: node)
    when {:u8, :i32}  then zero_extend(7, node: node)
    when {:u8, :i64}  then nop
    when {:u8, :f32}  then u8_to_f32(node: node)
    when {:u8, :f64}  then u8_to_f64(node: node)
    when {:i16, :i8}  then nop
    when {:i16, :i16} then nop
    when {:i16, :i32} then sign_extend(6, node: node)
    when {:i16, :i64} then sign_extend(6, node: node)
    when {:i16, :f32} then i16_to_f32(node: node)
    when {:i16, :f64} then i16_to_f64(node: node)
    when {:u16, :i8}  then nop
    when {:u16, :i16} then nop
    when {:u16, :i32} then zero_extend(6, node: node)
    when {:u16, :i64} then zero_extend(6, node: node)
    when {:u16, :f32} then u16_to_f32(node: node)
    when {:u16, :f64} then u16_to_f64(node: node)
    when {:i32, :i8}  then nop
    when {:i32, :i16} then nop
    when {:i32, :i32} then nop
    when {:i32, :i64} then sign_extend(4, node: node)
    when {:i32, :f32} then i32_to_f32(node: node)
    when {:i32, :f64} then i32_to_f64(node: node)
    when {:u32, :i8}  then nop
    when {:u32, :i16} then nop
    when {:u32, :i32} then nop
    when {:u32, :u32} then nop
    when {:u32, :i64} then zero_extend(4, node: node)
    when {:u32, :f32} then u32_to_f32(node: node)
    when {:u32, :f64} then u32_to_f64(node: node)
    when {:i64, :i8}  then nop
    when {:i64, :i16} then nop
    when {:i64, :i32} then nop
    when {:i64, :i64} then nop
    when {:i64, :f32} then i64_to_f32(node: node)
    when {:i64, :f64} then i64_to_f64(node: node)
    when {:u64, :i8}  then nop
    when {:u64, :i16} then nop
    when {:u64, :i32} then nop
    when {:u64, :i64} then nop
    when {:u64, :f32} then u64_to_f32(node: node)
    when {:u64, :f64} then u64_to_f64(node: node)
    when {:f32, :i8}  then f32_to_i64_bang(node: node)
    when {:f32, :i16} then f32_to_i64_bang(node: node)
    when {:f32, :i32} then f32_to_i64_bang(node: node)
    when {:f32, :i64} then f32_to_i64_bang(node: node)
    when {:f32, :f32} then nop
    when {:f32, :f64} then f32_to_f64(node: node)
    when {:f64, :i8}  then f64_to_i64_bang(node: node)
    when {:f64, :i16} then f64_to_i64_bang(node: node)
    when {:f64, :i32} then f64_to_i64_bang(node: node)
    when {:f64, :i64} then f64_to_i64_bang(node: node)
    when {:f64, :f32} then f64_to_f32_bang(node: node)
    when {:f64, :f64} then nop
    else                   node.raise "BUG: missing handling of unchecked_convert for #{from_kind} - #{to_kind}"
    end
  end

  private def primitive_binary(node, body)
    unless @wants_value
      node.obj.try &.accept self
      node.args.each &.accept self
      node.named_args.try &.each &.value.accept self
      return
    end

    case node.name
    when "+", "&+", "-", "&-", "*", "&*", "^", "|", "&", "unsafe_shl", "unsafe_shr", "unsafe_div", "unsafe_mod"
      primitive_binary_op_math(node, body, node.name)
    when "<", "<=", ">", ">=", "==", "!="
      primitive_binary_op_cmp(node, body, node.name)
    when "/"
      primitive_binary_float_div(node, body)
    else
      node.raise "BUG: missing handling of binary op #{node.name}"
    end
  end

  private def primitive_binary_op_math(node : ASTNode, body : Primitive, op : String)
    obj = node.obj
    arg = node.args.first

    obj_type = obj.try(&.type) || scope
    arg_type = arg.type

    primitive_binary_op_math(obj_type, arg_type, obj, arg, node, op)
  end

  private def primitive_binary_op_math(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode?, right_node : ASTNode, node : ASTNode, op : String)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      # Go on
      return false unless @wants_value

      primitive_binary_op_math(node, kind, op)
    elsif left_type.rank > right_type.rank
      # It's UInt64 op X where X is a signed integer
      left_node ? left_node.accept(self) : put_self(node: node)
      right_node.accept self
      primitive_unchecked_convert node, right_type.kind, :i64

      case node.name
      when "+"          then add_u64_i64(node: node)
      when "&+"         then add_wrap_i64(node: node)
      when "-"          then sub_u64_i64(node: node)
      when "&-"         then sub_wrap_i64(node: node)
      when "*"          then mul_u64_i64(node: node)
      when "&*"         then mul_wrap_i64(node: node)
      when "^"          then xor_i64(node: node)
      when "|"          then or_i64(node: node)
      when "&"          then or_i64(node: node)
      when "unsafe_shl" then unsafe_shl_i64(node: node)
      when "unsafe_shr" then unsafe_shr_u64_i64(node: node)
      when "unsafe_div" then unsafe_div_u64_i64(node: node)
      when "unsafe_mod" then unsafe_mod_u64_i64(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
      end

      kind = :u64
    else
      # It's X op UInt64 where X is a signed integer
      left_node ? left_node.accept(self) : put_self(node: node)
      primitive_unchecked_convert node, left_type.kind, :i64
      right_node.accept self

      case node.name
      when "+"          then add_i64_u64(node: node)
      when "&+"         then add_wrap_i64(node: node)
      when "-"          then sub_i64_u64(node: node)
      when "&-"         then sub_wrap_i64(node: node)
      when "*"          then mul_i64_u64(node: node)
      when "&*"         then mul_wrap_i64(node: node)
      when "^"          then xor_i64(node: node)
      when "|"          then or_i64(node: node)
      when "&"          then or_i64(node: node)
      when "unsafe_shl" then unsafe_shl_i64(node: node)
      when "unsafe_shr" then unsafe_shr_i64_u64(node: node)
      when "unsafe_div" then unsafe_div_i64_u64(node: node)
      when "unsafe_mod" then unsafe_mod_i64_u64(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
      end

      kind = :i64
    end

    if kind != left_type.kind
      # TODO: check overflow here
      primitive_unchecked_convert(node, kind, left_type.kind)
    end
  end

  private def primitive_binary_op_math(left_type : IntegerType, right_type : FloatType, left_node : ASTNode?, right_node : ASTNode, node : ASTNode, op : String)
    left_node ? left_node.accept(self) : put_self(node: node)
    primitive_unchecked_convert node, left_type.kind, right_type.kind
    right_node.accept self

    primitive_binary_op_math(node, right_type.kind, op)
  end

  private def primitive_binary_op_math(left_type : FloatType, right_type : IntegerType, left_node : ASTNode?, right_node : ASTNode, node : ASTNode, op : String)
    left_node ? left_node.accept(self) : put_self(node: node)
    right_node.accept self
    primitive_unchecked_convert right_node, right_type.kind, left_type.kind

    primitive_binary_op_math(node, left_type.kind, op)
  end

  private def primitive_binary_op_math(left_type : FloatType, right_type : FloatType, left_node : ASTNode?, right_node : ASTNode, node : ASTNode, op : String)
    if left_type == right_type
      left_node ? left_node.accept(self) : put_self(node: node)
      right_node.accept self
    else
      node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
    end

    primitive_binary_op_math(node, left_type.kind, op)
  end

  private def primitive_binary_op_math(node : ASTNode, kind : Symbol, op : String)
    case kind
    when :i32
      case op
      when "+"          then add_i32(node: node)
      when "&+"         then add_wrap_i32(node: node)
      when "-"          then sub_i32(node: node)
      when "&-"         then sub_wrap_i32(node: node)
      when "*"          then mul_i32(node: node)
      when "&*"         then mul_wrap_i32(node: node)
      when "^"          then xor_i32(node: node)
      when "|"          then or_i32(node: node)
      when "&"          then and_i32(node: node)
      when "unsafe_shl" then unsafe_shl_i32(node: node)
      when "unsafe_shr" then unsafe_shr_i32(node: node)
      when "unsafe_div" then unsafe_div_i32(node: node)
      when "unsafe_mod" then unsafe_mod_i32(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
      end
    when :u32
      case op
      when "+"          then add_u32(node: node)
      when "&+"         then add_wrap_i32(node: node)
      when "-"          then sub_u32(node: node)
      when "&-"         then sub_wrap_i32(node: node)
      when "*"          then mul_u32(node: node)
      when "&*"         then mul_wrap_i32(node: node)
      when "^"          then xor_i32(node: node)
      when "|"          then or_i32(node: node)
      when "&"          then and_i32(node: node)
      when "unsafe_shl" then unsafe_shl_i32(node: node)
      when "unsafe_shr" then unsafe_shr_u32(node: node)
      when "unsafe_div" then unsafe_div_u32(node: node)
      when "unsafe_mod" then unsafe_mod_u32(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
      end
    when :i64
      case op
      when "+"          then add_i64(node: node)
      when "&+"         then add_wrap_i64(node: node)
      when "-"          then sub_i64(node: node)
      when "&-"         then sub_wrap_i64(node: node)
      when "*"          then mul_i64(node: node)
      when "&*"         then mul_wrap_i64(node: node)
      when "^"          then xor_i64(node: node)
      when "|"          then or_i64(node: node)
      when "&"          then and_i64(node: node)
      when "unsafe_shl" then unsafe_shl_i64(node: node)
      when "unsafe_shr" then unsafe_shr_i64(node: node)
      when "unsafe_div" then unsafe_div_i64(node: node)
      when "unsafe_mod" then unsafe_mod_i64(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
      end
    when :u64
      case op
      when "+"          then add_u64(node: node)
      when "&+"         then add_wrap_i64(node: node)
      when "-"          then sub_u64(node: node)
      when "&-"         then sub_wrap_i64(node: node)
      when "*"          then mul_u64(node: node)
      when "&*"         then mul_wrap_i64(node: node)
      when "^"          then xor_i64(node: node)
      when "|"          then or_i64(node: node)
      when "&"          then and_i64(node: node)
      when "unsafe_shl" then unsafe_shl_i64(node: node)
      when "unsafe_shr" then unsafe_shr_u64(node: node)
      when "unsafe_div" then unsafe_div_u64(node: node)
      when "unsafe_mod" then unsafe_mod_u64(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
      end
    when :f32
      node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
    when :f64
      case op
      when "+" then add_f64(node: node)
      when "-" then sub_f64(node: node)
      when "*" then mul_f64(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
      end
    else
      node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
    end
  end

  private def primitive_binary_op_math(left_type : Type, right_type : Type, left_node : ASTNode?, right_node : ASTNode, node : ASTNode, op : String)
    node.raise "BUG: primitive_binary_op_math called with #{left_type} #{op} #{right_type}"
  end

  private def primitive_binary_op_cmp(node : ASTNode, body : Primitive, op : String)
    obj = node.obj.not_nil!
    arg = node.args.first

    obj_type = obj.type
    arg_type = arg.type

    primitive_binary_op_cmp(obj_type, arg_type, obj, arg, node, op)
  end

  private def primitive_binary_op_cmp(left_type : BoolType, right_type : BoolType, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    left_node.accept self
    right_node.accept self

    case op
    when "==" then eq_bool(node: node)
    when "!=" then neq_bool(node: node)
    else
      left_node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
    end
  end

  private def primitive_binary_op_cmp(left_type : CharType, right_type : CharType, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    left_node.accept self
    right_node.accept self

    case op
    when "==" then eq_i32(node: node)
    when "!=" then neq_i32(node: node)
    when "<"  then lt_i32(node: node)
    when "<=" then le_i32(node: node)
    when ">"  then gt_i32(node: node)
    when ">=" then ge_i32(node: node)
    else
      left_node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
    end
  end

  private def primitive_binary_op_cmp(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    case op
    when "==" then primitive_binary_op_eq(left_type, right_type, left_node, right_node, node)
    when "!=" then primitive_binary_op_neq(left_type, right_type, left_node, right_node, node)
    when "<"  then primitive_binary_op_lt(left_type, right_type, left_node, right_node, node)
    when "<=" then primitive_binary_op_le(left_type, right_type, left_node, right_node, node)
    when ">"  then primitive_binary_op_gt(left_type, right_type, left_node, right_node, node)
    when ">=" then primitive_binary_op_ge(left_type, right_type, left_node, right_node, node)
    else
      left_node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
    end
  end

  private def primitive_binary_op_cmp(left_type : FloatType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    left_node.accept self
    right_node.accept self
    primitive_unchecked_convert right_node, right_type.kind, left_type.kind

    primitive_binary_op_cmp_float(node, left_type.kind, op)
  end

  private def primitive_binary_op_cmp(left_type : IntegerType, right_type : FloatType, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    left_node.accept self
    primitive_unchecked_convert(left_node, left_type.kind, right_type.kind)
    right_node.accept self

    primitive_binary_op_cmp_float(node, right_type.kind, op)
  end

  private def primitive_binary_op_cmp(left_type : FloatType, right_type : FloatType, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    if left_type == right_type
      left_node.accept self
      right_node.accept self

      primitive_binary_op_cmp_float(node, left_type.kind, op)
    else
      left_node.raise "BUG: missing handling of binary #{op} with types #{left_type} and #{right_type}"
    end
  end

  private def primitive_binary_op_cmp(left_type : Type, right_type : Type, left_node : ASTNode, right_node : ASTNode, node : ASTNode, op : String)
    left_node.raise "BUG: primitive_binary_op_cmp called with #{left_type} #{op} #{right_type}"
  end

  private def primitive_binary_op_cmp_float(node : ASTNode, kind : Symbol, op : String)
    case kind
    when :f64
      case op
      when "==" then eq_f64(node: node)
      when "!=" then neq_f64(node: node)
      when "<"  then lt_f64(node: node)
      when "<=" then le_f64(node: node)
      when ">"  then gt_f64(node: node)
      when ">=" then ge_f64(node: node)
      else
        node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
      end
    else
      node.raise "BUG: missing handling of binary #{op} with kind #{kind}"
    end
  end

  private def primitive_binary_op_eq(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      primitive_binary_op_eq(node, kind)
    elsif left_type.rank > right_type.rank
      # It's UInt64 == X where X is a signed integer.

      # We first extend right to left
      left_node.accept self
      right_node.accept self
      primitive_unchecked_convert right_node, right_type.kind, :i64

      eq_u64_i64(node: node)
    else
      # It's X == UInt64 where X is a signed integer.
      # We must do: left >= 0 && left == right
      left_node.raise "BUG: missing handling of binary == with types #{left_type} and #{right_type}"
    end
  end

  private def primitive_binary_op_eq(node : ASTNode, kind : Symbol)
    case kind
    when :i32, :u32 then eq_i32(node: node)
    when :i64, :u64 then eq_i64(node: node)
    else
      node.raise "BUG: missing handling of binary == for #{kind}"
    end
  end

  private def primitive_binary_op_neq(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      primitive_binary_op_neq(node, kind)
    else
      left_node.raise "BUG: missing handling of binary == with types #{left_type} and #{right_type}"
    end
  end

  private def primitive_binary_op_neq(node : ASTNode, kind : Symbol)
    case kind
    when :i32, :u32 then neq_i32(node: node)
    when :i64, :u64 then neq_i64(node: node)
    else
      node.raise "BUG: missing handling of binary != for #{kind}"
    end
  end

  private def primitive_binary_op_lt(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      primitive_binary_op_lt(node, kind)
    elsif left_type.rank > right_type.rank
      # It's UInt64 < X where X is a signed integer
      left_node.accept self
      right_node.accept self
      primitive_unchecked_convert right_node, right_type.kind, :i64
      lt_u64_i64(node: node)
    else
      # It's X < UInt64 where X is a signed integer
      left_node.accept self
      primitive_unchecked_convert left_node, left_type.kind, :i64
      right_node.accept self
      lt_i64_u64(node: node)
    end
  end

  private def primitive_binary_op_lt(node : ASTNode, kind : Symbol)
    case kind
    when :i32 then lt_i32(node: node)
    when :u32 then lt_u32(node: node)
    when :i64 then lt_i64(node: node)
    when :u64 then lt_u64(node: node)
    else
      node.raise "BUG: missing handling of binary < for #{kind}"
    end
  end

  private def primitive_binary_op_le(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      primitive_binary_op_le(node, kind)
    elsif left_type.rank > right_type.rank
      # It's UInt64 <= X where X is a signed integer
      left_node.accept self
      right_node.accept self
      primitive_unchecked_convert right_node, right_type.kind, :i64
      le_u64_i64(node: node)
    else
      # It's X <= UInt64 where X is a signed integer
      left_node.accept self
      primitive_unchecked_convert left_node, left_type.kind, :i64
      right_node.accept self
      le_i64_u64(node: node)
    end
  end

  private def primitive_binary_op_le(node : ASTNode, kind : Symbol)
    case kind
    when :i32 then le_i32(node: node)
    when :u32 then le_u32(node: node)
    when :i64 then le_i64(node: node)
    when :u64 then le_u64(node: node)
    else
      node.raise "BUG: missing handling of binary <= for #{kind}"
    end
  end

  private def primitive_binary_op_gt(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      primitive_binary_op_gt(node, kind)
    elsif left_type.rank > right_type.rank
      # It's UInt64 > X where X is a signed integer
      left_node.accept self
      right_node.accept self
      primitive_unchecked_convert right_node, right_type.kind, :i64
      gt_u64_i64(node: node)
    else
      # It's X > UInt64 where X is a signed integer
      left_node.accept self
      primitive_unchecked_convert left_node, left_type.kind, :i64
      right_node.accept self
      gt_i64_u64(node: node)
    end
  end

  private def primitive_binary_op_gt(node : ASTNode, kind : Symbol)
    case kind
    when :i32 then gt_i32(node: node)
    when :u32 then gt_u32(node: node)
    when :i64 then gt_i64(node: node)
    when :u64 then gt_u64(node: node)
    else
      node.raise "BUG: missing handling of binary > for #{kind}"
    end
  end

  private def primitive_binary_op_ge(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode, right_node : ASTNode, node : ASTNode)
    kind = extend_int(left_type, right_type, left_node, right_node, node)
    if kind
      primitive_binary_op_ge(node, kind)
    elsif left_type.rank > right_type.rank
      # It's UInt64 >= X where X is a signed integer
      left_node.accept self
      right_node.accept self
      primitive_unchecked_convert right_node, right_type.kind, :i64
      ge_u64_i64(node: node)
    else
      # It's X >= UInt64 where X is a signed integer
      left_node.accept self
      primitive_unchecked_convert left_node, left_type.kind, :i64
      right_node.accept self
      ge_i64_u64(node: node)
    end
  end

  private def primitive_binary_op_ge(node : ASTNode, kind : Symbol)
    case kind
    when :i32 then ge_i32(node: node)
    when :u32 then ge_u32(node: node)
    when :i64 then ge_i64(node: node)
    when :u64 then ge_u64(node: node)
    else
      node.raise "BUG: missing handling of binary >= for #{kind}"
    end
  end

  private def extend_int(left_type : IntegerType, right_type : IntegerType, left_node : ASTNode?, right_node : ASTNode, node : ASTNode)
    if left_type.signed? == right_type.signed?
      if left_type.rank == right_type.rank
        left_node ? left_node.accept(self) : put_self(node: node)
        right_node.accept self
        left_type.kind
      elsif left_type.rank < right_type.rank
        left_node ? left_node.accept(self) : put_self(node: node)
        primitive_unchecked_convert(left_node || right_node, left_type.kind, right_type.kind)
        right_node.accept self
        right_type.kind
      else
        left_node ? left_node.accept(self) : put_self(node: node)
        right_node.accept self
        primitive_unchecked_convert right_node, right_type.kind, left_type.kind
        left_type.kind
      end
    elsif left_type.rank <= 5 && right_type.rank <= 5
      # If both fit in an Int32
      # Convert them to Int32 first, then do the comparison
      left_node ? left_node.accept(self) : put_self(node: node)
      primitive_unchecked_convert(left_node || right_node, left_type.kind, :i32) if left_type.rank < 5

      right_node.accept self
      primitive_unchecked_convert(right_node, right_type.kind, :i32) if right_type.rank < 5

      :i32
    elsif left_type.rank <= 7 && right_type.rank <= 7
      # If both fit in an Int64
      # Convert them to Int64 first, then do the comparison
      left_node ? left_node.accept(self) : put_self(node: node)
      primitive_unchecked_convert(left_node || right_node, left_type.kind, :i64) if left_type.rank < 7

      right_node.accept self
      primitive_unchecked_convert(right_node, right_type.kind, :i64) if right_type.rank < 7

      :i64
    else
      nil
    end
  end

  private def primitive_binary_float_div(node : ASTNode, body)
    # TODO: don't assume Float64 op Float64
    obj = node.obj.not_nil!
    arg = node.args.first

    obj.accept self
    arg.accept self

    obj_type = obj.type
    arg_type = arg.type

    obj_kind = integer_or_float_kind(obj_type)
    target_kind = integer_or_float_kind(arg_type)

    case {obj_kind, target_kind}
    when {:f64, :f64}
      div_f64(node: node)
    else
      node.raise "BUG: missing handling of binary float div with types #{obj_type} and #{arg_type}"
    end
  end

  private def integer_or_float_kind(type)
    case type
    when IntegerType
      type.kind
    when FloatType
      type.kind
    else
      nil
    end
  end
end