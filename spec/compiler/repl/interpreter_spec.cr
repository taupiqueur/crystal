require "../spec_helper"

describe Crystal::Repl::Interpreter do
  context "literals" do
    it "interprets nil" do
      interpret("nil").should be_nil
    end

    it "interprets a bool (false)" do
      interpret("false").should be_false
    end

    it "interprets a bool (true)" do
      interpret("true").should be_true
    end

    it "interprets an Int8" do
      interpret("123_i8").should eq(123_i8)
    end

    it "interprets an UInt8" do
      interpret("145_u8").should eq(145_u8)
    end

    it "interprets an Int16" do
      interpret("12345_i16").should eq(12345_i16)
    end

    it "interprets an UInt16" do
      interpret("12389_u16").should eq(12389_u16)
    end

    it "interprets an Int32" do
      interpret("123456789_i32").should eq(123456789)
    end

    it "interprets an UInt32" do
      interpret("323456789_u32").should eq(323456789_u32)
    end

    it "interprets an Int64" do
      interpret("123_i64").should eq(123_i64)
    end

    it "interprets an UInt64" do
      interpret("123_u64").should eq(123_u64)
    end

    it "interprets a Float32" do
      interpret("1.5_f32").should eq(1.5_f32)
    end

    it "interprets a Float64" do
      interpret("1.5").should eq(1.5)
    end

    it "interprets a char" do
      interpret("'a'").should eq('a')
    end

    it "interprets a String literal" do
      interpret(%("Hello world!")).should eq("Hello world!")
    end
  end

  context "local variables" do
    it "interprets variable set" do
      interpret(<<-CODE).should eq(1)
      a = 1
      CODE
    end

    it "interprets variable set and get" do
      interpret(<<-CODE).should eq(1)
      a = 1
      a
      CODE
    end

    it "interprets variable set and get, second local var" do
      interpret(<<-CODE).should eq(1)
      x = 10
      a = 1
      a
      CODE
    end

    it "interprets variable set and get with operations" do
      interpret(<<-CODE).should eq(6)
      a = 1
      b = 2
      c = 3
      a + b + c
      CODE
    end

    it "interprets uninitialized" do
      interpret(<<-CODE).should eq(3)
        a = uninitialized Int32
        a = 3
        a
        CODE
    end
  end

  context "conversion" do
    {% for target_type in %w(u8 i8 u16 i16 u32 i32 u i u64 i64 f32 f64).map(&.id) %}
      it "interprets Int8::MAX#to_{{target_type}}!" do
        interpret("#{Int8::MAX}_i8.to_{{target_type}}!").should eq(Int8::MAX.to_{{target_type}}!)
      end

      it "interprets Int8::MIN#to_{{target_type}}!" do
        interpret("#{Int8::MIN}_i8.to_{{target_type}}!").should eq(Int8::MIN.to_{{target_type}}!)
      end

      it "interprets UInt8::MAX#to_{{target_type}}!" do
        interpret("#{UInt8::MAX}_u8.to_{{target_type}}!").should eq(UInt8::MAX.to_{{target_type}}!)
      end

      it "interprets Int16::MAX#to_{{target_type}}!" do
        interpret("#{Int16::MAX}_i16.to_{{target_type}}!").should eq(Int16::MAX.to_{{target_type}}!)
      end

      it "interprets Int16::MIN#to_{{target_type}}!" do
        interpret("#{Int16::MIN}_i16.to_{{target_type}}!").should eq(Int16::MIN.to_{{target_type}}!)
      end

      it "interprets UInt16::MAX#to_{{target_type}}!" do
        interpret("#{UInt16::MAX}_u16.to_{{target_type}}!").should eq(UInt16::MAX.to_{{target_type}}!)
      end

      it "interprets Int32::MAX#to_{{target_type}}!" do
        interpret("#{Int32::MAX}.to_{{target_type}}!").should eq(Int32::MAX.to_{{target_type}}!)
      end

      it "interprets Int32::MIN#to_{{target_type}}!" do
        interpret("#{Int32::MIN}.to_{{target_type}}!").should eq(Int32::MIN.to_{{target_type}}!)
      end

      it "interprets UInt32::MAX#to_{{target_type}}!" do
        interpret("#{UInt32::MAX}_u32.to_{{target_type}}!").should eq(UInt32::MAX.to_{{target_type}}!)
      end

      it "interprets Int64::MAX#to_{{target_type}}!" do
        interpret("#{Int64::MAX}_i64.to_{{target_type}}!").should eq(Int64::MAX.to_{{target_type}}!)
      end

      it "interprets Int64::MIN#to_{{target_type}}!" do
        interpret("#{Int64::MIN}_i64.to_{{target_type}}!").should eq(Int64::MIN.to_{{target_type}}!)
      end

      it "interprets UInt64::MAX#to_{{target_type}}!" do
        interpret("#{UInt64::MAX}_u64.to_{{target_type}}!").should eq(UInt64::MAX.to_{{target_type}}!)
      end

      it "interprets Float32#to_{{target_type}}! (positive)" do
        f = 23.8_f32
        interpret("23.8_f32.to_{{target_type}}!").should eq(f.to_{{target_type}}!)
      end

      it "interprets Float32#to_{{target_type}}! (negative)" do
        f = -23.8_f32
        interpret("-23.8_f32.to_{{target_type}}!").should eq(f.to_{{target_type}}!)
      end

      it "interprets Float64#to_{{target_type}}! (positive)" do
        f = 23.8_f64
        interpret("23.8_f64.to_{{target_type}}!").should eq(f.to_{{target_type}}!)
      end

      it "interprets Float64#to_{{target_type}}! (negative)" do
        f = -23.8_f64
        interpret("-23.8_f64.to_{{target_type}}!").should eq(f.to_{{target_type}}!)
      end
    {% end %}

    it "interprets Char#ord" do
      interpret("'a'.ord").should eq('a'.ord)
    end

    it "Int32#unsafe_chr" do
      interpret("97.unsafe_chr").should eq(97.unsafe_chr)
    end

    it "UInt8#unsafe_chr" do
      interpret("97_u8.unsafe_chr").should eq(97.unsafe_chr)
    end

    it "discards conversion" do
      interpret(<<-CODE).should eq(3)
      1.to_i8!
      3
      CODE
    end

    it "discards conversion with local var" do
      interpret(<<-CODE).should eq(3)
      x = 1
      x.to_i8!
      3
      CODE
    end
  end

  context "math" do
    it "interprets Int32 + Int32" do
      interpret("1 + 2").should eq(3)
    end

    it "interprets Int32 &+ Int32" do
      interpret("1 &+ 2").should eq(3)
    end

    it "interprets Int64 + Int64" do
      interpret("1_i64 + 2_i64").should eq(3)
    end

    it "interprets Int32 - Int32" do
      interpret("1 - 2").should eq(-1)
    end

    it "interprets Int32 &- Int32" do
      interpret("1 &- 2").should eq(-1)
    end

    it "interprets Int32 * Int32" do
      interpret("2 * 3").should eq(6)
    end

    it "interprets Int32 &* Int32" do
      interpret("2 &* 3").should eq(6)
    end

    it "interprets UInt64 * Int32" do
      interpret("2_u64 * 3").should eq(6)
    end

    it "interprets UInt8 | Int32" do
      interpret("1_u8 | 2").should eq(3)
    end

    it "interprets UInt64 | UInt32" do
      interpret("1_u64 | 2_u32").should eq(3)
    end

    it "interprets UInt32 - Int32" do
      interpret("3_u32 - 2").should eq(1)
    end

    it "interprets Int32 + Float64" do
      interpret("1 + 2.5").should eq(3.5)
    end

    it "interprets Float64 + Int32" do
      interpret("2.5 + 1").should eq(3.5)
    end

    it "interprets Float64 + Float64" do
      interpret("2.5 + 2.3").should eq(4.8)
    end

    it "interprets Float64 - Float64" do
      interpret("2.5 - 2.3").should eq(2.5 - 2.3)
    end

    it "interprets Float64 * Float64" do
      interpret("2.5 * 2.3").should eq(2.5 * 2.3)
    end

    it "discards math" do
      interpret("1 + 2; 4").should eq(4)
    end
  end

  context "comparisons" do
    it "interprets Bool == Bool (false)" do
      interpret("true == false").should be_false
    end

    it "interprets Bool == Bool (true)" do
      interpret("true == true").should be_true
    end

    it "interprets Bool != Bool (false)" do
      interpret("true != true").should be_false
    end

    it "interprets Bool != Bool (true)" do
      interpret("true != false").should be_true
    end

    it "interprets Int32 < Int32" do
      interpret("1 < 2").should be_true
    end

    it "interprets Int32 == Int32 (true)" do
      interpret("1 == 1").should be_true
    end

    it "interprets Int32 == Int32 (false)" do
      interpret("1 == 2").should be_false
    end

    it "interprets Int32 != Int32 (true)" do
      interpret("1 != 2").should be_true
    end

    it "interprets Int32 != Int32 (false)" do
      interpret("1 != 1").should be_false
    end

    it "interprets Float64 / Float64" do
      interpret("2.5 / 2.1").should eq(2.5 / 2.1)
    end

    it "interprets Int32 == Float64 (true)" do
      interpret("1 == 1.0").should be_true
    end

    it "interprets Int32 == Float64 (false)" do
      interpret("1 == 1.2").should be_false
    end

    it "interprets Int32 > Float64 (true)" do
      interpret("2 > 1.9").should be_true
    end

    it "interprets Int32 > Float64 (false)" do
      interpret("2 > 2.1").should be_false
    end

    it "interprets UInt8 < Int32 (true, right is greater than zero)" do
      interpret("1_u8 < 2").should be_true
    end

    it "interprets UInt8 < Int32 (false, right is greater than zero)" do
      interpret("1_u8 < 0").should be_false
    end

    it "interprets UInt8 < Int32 (false, right is less than zero)" do
      interpret("1_u8 < -1").should be_false
    end

    it "interprets UInt64 < Int32 (true, right is greater than zero)" do
      interpret("1_u64 < 2").should be_true
    end

    it "interprets UInt64 < Int32 (false, right is greater than zero)" do
      interpret("1_u64 < 0").should be_false
    end

    it "interprets UInt64 < Int32 (false, right is less than zero)" do
      interpret("1_u64 < -1").should be_false
    end

    it "interprets UInt64 > UInt32 (true)" do
      interpret("1_u64 > 0_u32").should be_true
    end

    it "interprets UInt64 > UInt32 (false)" do
      interpret("0_u64 > 1_u32").should be_false
    end

    it "interprets UInt32 < Int32 (true)" do
      interpret("1_u32 < 2").should be_true
    end

    it "interprets UInt32 < Int32 (false)" do
      interpret("1_u32 < 1").should be_false
    end

    it "interprets UInt64 == Int32 (false when Int32 < 0)" do
      interpret("1_u64 == -1").should be_false
    end

    it "interprets UInt64 == Int32 (false when Int32 >= 0)" do
      interpret("1_u64 == 0").should be_false
    end

    it "interprets UInt64 == Int32 (true when Int32 >= 0)" do
      interpret("1_u64 == 1").should be_true
    end

    it "interprets Char == Char (false)" do
      interpret("'a' == 'b'").should be_false
    end

    it "interprets Char == Char (true)" do
      interpret("'a' == 'a'").should be_true
    end

    it "interprets Int32 < Float64" do
      interpret("1 < 2.5").should be_true
    end

    it "interprets Float64 < Int32" do
      interpret("1.2 < 2").should be_true
    end

    it "interprets Float64 < Float64" do
      interpret("1.2 < 2.3").should be_true
    end

    it "discards comparison" do
      interpret("1 < 2; 3").should eq(3)
    end
  end

  context "logical operations" do
    it "interprets not for nil" do
      interpret("!nil").should eq(true)
    end

    it "interprets not for nil type" do
      interpret("x = 1; !(x = 2; nil); x").should eq(2)
    end

    it "interprets not for bool true" do
      interpret("!true").should eq(false)
    end

    it "interprets not for bool false" do
      interpret("!false").should eq(true)
    end

    it "discards nil not" do
      interpret("!nil; 3").should eq(3)
    end

    it "discards bool not" do
      interpret("!false; 3").should eq(3)
    end

    it "interprets not for bool false" do
      interpret("!false").should eq(true)
    end

    it "interprets not for mixed union (nil)" do
      interpret("!(1 == 1 ? nil : 2)").should eq(true)
    end

    it "interprets not for mixed union (false)" do
      interpret("!(1 == 1 ? false : 2)").should eq(true)
    end

    it "interprets not for mixed union (true)" do
      interpret("!(1 == 1 ? true : 2)").should eq(false)
    end

    it "interprets not for mixed union (other)" do
      interpret("!(1 == 1 ? 2 : true)").should eq(false)
    end

    it "interprets not for nilable type (false)" do
      interpret(%(!(1 == 1 ? "hello" : nil))).should eq(false)
    end

    it "interprets not for nilable type (true)" do
      interpret(%(!(1 == 1 ? nil : "hello"))).should eq(true)
    end

    it "interprets Int32.unsafe_shl(Int32) with self" do
      interpret(<<-CODE).should eq(4)
        struct Int32
          def shl2
            unsafe_shl(2)
          end
        end

        a = 1
        a.shl2
        CODE
    end
  end

  context "control flow" do
    it "interprets if (true literal)" do
      interpret("true ? 2 : 3").should eq(2)
    end

    it "interprets if (false literal)" do
      interpret("false ? 2 : 3").should eq(3)
    end

    it "interprets if (nil literal)" do
      interpret("nil ? 2 : 3").should eq(3)
    end

    it "interprets if bool (true)" do
      interpret("1 == 1 ? 2 : 3").should eq(2)
    end

    it "interprets if bool (false)" do
      interpret("1 == 2 ? 2 : 3").should eq(3)
    end

    it "interprets if (nil type)" do
      interpret("a = nil; a ? 2 : 3").should eq(3)
    end

    it "interprets if (int type)" do
      interpret("a = 1; a ? 2 : 3").should eq(2)
    end

    it "interprets if union type with bool, true" do
      interpret("a = 1 == 1 ? 1 : false; a ? 2 : 3").should eq(2)
    end

    it "interprets if union type with bool, false" do
      interpret("a = 1 == 2 ? 1 : false; a ? 2 : 3").should eq(3)
    end

    it "interprets if union type with nil, false" do
      interpret("a = 1 == 2 ? 1 : nil; a ? 2 : 3").should eq(3)
    end

    it "interprets if pointer, true" do
      interpret("ptr = Pointer(Int32).new(1_u64); ptr ? 2 : 3").should eq(2)
    end

    it "interprets if pointer, false" do
      interpret("ptr = Pointer(Int32).new(0_u64); ptr ? 2 : 3").should eq(3)
    end

    it "interprets unless" do
      interpret("unless 1 == 1; 2; else; 3; end").should eq(3)
    end

    it "discards if" do
      interpret("1 == 1 ? 2 : 3; 4").should eq(4)
    end

    it "interprets while" do
      interpret(<<-CODE).should eq(10)
        a = 0
        while a < 10
          a = a + 1
        end
        a
        CODE
    end

    it "interprets while, returns nil" do
      interpret(<<-CODE).should eq(nil)
        a = 0
        while a < 10
          a = a + 1
        end
        CODE
    end

    it "interprets until" do
      interpret(<<-CODE).should eq(10)
        a = 0
        until a == 10
          a = a + 1
        end
        a
      CODE
    end

    it "discards while" do
      interpret("while 1 == 2; 3; end; 4").should eq(4)
    end

    it "interprets return" do
      interpret(<<-CODE).should eq(2)
        def foo(x)
          if x == 1
            return 2
          end

          3
        end

        foo(1)
      CODE
    end

    it "interprets return Nil" do
      interpret(<<-CODE).should be_nil
        def foo : Nil
          1
        end

        foo
      CODE
    end

    it "interprets return implicit nil and Int32" do
      interpret(<<-CODE).should eq(10)
        def foo(x)
          if x == 1
            return
          end

          3
        end

        z = foo(1)
        if z.is_a?(Int32)
          z
        else
          10
        end
      CODE
    end
  end

  context "pointers" do
    it "interprets pointer set and get (int)" do
      interpret(<<-CODE).should eq(10)
        ptr = Pointer(Int32).malloc(1_u64)
        ptr.value = 10
        ptr.value
      CODE
    end

    it "interprets pointer set and get (bool)" do
      interpret(<<-CODE).should be_true
        ptr = Pointer(Bool).malloc(1_u64)
        ptr.value = true
        ptr.value
      CODE
    end

    it "interprets pointer set and get (clear stack)" do
      interpret(<<-CODE).should eq(50.unsafe_chr)
        ptr = Pointer(UInt8).malloc(1_u64)
        ptr.value = 50_u8
        ptr.value.unsafe_chr
      CODE
    end

    it "interprets pointerof, mutates pointer, read var" do
      interpret(<<-CODE).should eq(2)
        a = 1
        ptr = pointerof(a)
        ptr.value = 2
        a
      CODE
    end

    it "interprets pointerof, mutates var, read pointer" do
      interpret(<<-CODE).should eq(2)
        a = 1
        ptr = pointerof(a)
        a = 2
        ptr.value
      CODE
    end

    it "interprets pointerof and mutates memory (there are more variables)" do
      interpret(<<-CODE).should eq(2)
        x = 42
        a = 1
        ptr = pointerof(a)
        ptr.value = 2
        a
      CODE
    end

    it "pointerof instance var" do
      interpret(<<-EXISTING, <<-CODE).should eq(2)
        class Foo
          def initialize(@x : Int32)
          end

          def x
            @x
          end

          def x_ptr
            pointerof(@x)
          end
        end
      EXISTING
        foo = Foo.new(1)
        ptr = foo.x_ptr
        ptr.value = 2
        foo.x
      CODE
    end

    # it "interprets pointer set and get (union type)" do
    #   interpret(<<-CODE).should eq(true)
    #     ptr = Pointer(Int32 | Bool).malloc(1_u64)
    #     ptr.value = 10
    #     ptr.value = true
    #     ptr.value
    #   CODE
    # end

    it "interprets pointer new and pointer address" do
      interpret(<<-CODE).should eq(123_u64)
        ptr = Pointer(Int32 | Bool).new(123_u64)
        ptr.address
      CODE
    end

    it "interprets pointer diff" do
      interpret(<<-CODE).should eq(8_i64)
        ptr1 = Pointer(Int32).new(133_u64)
        ptr2 = Pointer(Int32).new(100_u64)
        ptr1 - ptr2
      CODE
    end

    it "discards pointer malloc" do
      interpret(<<-CODE).should eq(1)
        Pointer(Int32).malloc(1_u64)
        1
      CODE
    end

    it "discards pointer get" do
      interpret(<<-CODE).should eq(1)
        ptr = Pointer(Int32).malloc(1_u64)
        ptr.value
        1
      CODE
    end

    it "discards pointer set" do
      interpret(<<-CODE).should eq(1)
        ptr = Pointer(Int32).malloc(1_u64)
        ptr.value = 1
      CODE
    end

    it "discards pointer new" do
      interpret(<<-CODE).should eq(1)
        Pointer(Int32).new(1_u64)
        1
      CODE
    end

    it "discards pointer diff" do
      interpret(<<-CODE).should eq(1)
        ptr1 = Pointer(Int32).new(133_u64)
        ptr2 = Pointer(Int32).new(100_u64)
        ptr1 - ptr2
        1
      CODE
    end

    it "discards pointerof" do
      interpret(<<-CODE).should eq(3)
        a = 1
        pointerof(a)
        3
      CODE
    end

    it "interprets pointer add" do
      interpret(<<-CODE).should eq(9)
        ptr = Pointer(Int32).new(1_u64)
        ptr2 = ptr + 2_i64
        ptr2.address
      CODE
    end

    it "discards pointer add" do
      interpret(<<-CODE).should eq(3)
        ptr = Pointer(Int32).new(1_u64)
        ptr + 2_i64
        3
      CODE
    end

    it "interprets pointer realloc" do
      interpret(<<-CODE).should eq(3)
        ptr = Pointer(Int32).malloc(1_u64)
        ptr2 = ptr.realloc(2_u64)
        3
      CODE
    end

    it "discards pointer realloc" do
      interpret(<<-CODE).should eq(3)
        ptr = Pointer(Int32).malloc(1_u64)
        ptr.realloc(2_u64)
        3
      CODE
    end

    it "interprets pointer realloc wrapper" do
      interpret(<<-CODE).should eq(3)
        struct Pointer(T)
          def realloc(n)
            realloc(n.to_u64)
          end
        end

        ptr = Pointer(Int32).malloc(1_u64)
        ptr2 = ptr.realloc(2)
        3
      CODE
    end
  end

  context "unions" do
    it "put and remove from union, together with is_a? (truthy case)" do
      interpret(<<-CODE).should eq(2)
        a = 1 == 1 ? 2 : true
        a.is_a?(Int32) ? a : 4
        CODE
    end

    it "put and remove from union, together with is_a? (falsey case)" do
      interpret(<<-CODE).should eq(true)
        a = 1 == 2 ? 2 : true
        a.is_a?(Int32) ? true : a
        CODE
    end

    it "returns union type" do
      interpret(<<-CODE).should eq('a')
        def foo
          if 1 == 1
            return 'a'
          end

          3
        end

        x = foo
        if x.is_a?(Char)
          x
        else
          'b'
        end
        CODE
    end

    it "put and remove from union in local var" do
      interpret(<<-CODE).should eq(3)
        a = 1 == 1 ? 2 : true
        a = 3
        a.is_a?(Int32) ? a : 4
        CODE
    end

    it "put and remove from union in instance var" do
      interpret(<<-EXISTING, <<-CODE).should eq(2)
        class Foo
          @x : Int32 | Char

          def initialize
            if 1 == 1
              @x = 2
            else
              @x = 'a'
            end
          end

          def x
            @x
          end
        end
      EXISTING
        foo = Foo.new
        z = foo.x
        if z.is_a?(Int32)
          z
        else
          10
        end
      CODE
    end

    it "discards is_a?" do
      interpret(<<-CODE).should eq(3)
        a = 1 == 1 ? 2 : true
        a.is_a?(Int32)
        3
        CODE
    end

    it "converts from NilableType to NonGenericClassType" do
      interpret(<<-CODE).should eq("a")
        a = 1 == 1 ? "a" : nil
        a || "b"
        CODE
    end
  end

  context "types" do
    it "interprets path to type" do
      program, repl_value = interpret_full("String")
      repl_value.value.should eq(program.string.metaclass)
    end

    it "interprets typeof instance type" do
      program, repl_value = interpret_full("typeof(1)")
      repl_value.value.should eq(program.int32.metaclass)
    end

    it "interprets typeof metaclass type" do
      program, repl_value = interpret_full("typeof(Int32)")
      repl_value.value.should eq(program.class_type)
    end

    it "interprets class for non-union type" do
      program, repl_value = interpret_full("1.class")
      repl_value.value.should eq(program.int32)
    end

    it "interprets crystal_type_id for nil" do
      interpret("nil.crystal_type_id").should eq(0)
    end

    it "interprets crystal_type_id for non-nil" do
      program, repl_value = interpret_full("1.crystal_type_id")
      repl_value.value.should eq(program.llvm_id.type_id(program.int32))
    end

    it "discards Path" do
      interpret("String; 1").should eq(1)
    end

    it "discards typeof" do
      interpret("typeof(1); 1").should eq(1)
    end

    it "discards generic" do
      interpret("Pointer(Int32); 1").should eq(1)
    end

    it "discards .class" do
      interpret("1.class; 1").should eq(1)
    end

    it "discards crystal_type_id" do
      interpret("nil.crystal_type_id; 1").should eq(1)
    end
  end

  context "calls" do
    it "calls a top-level method without arguments and no local vars" do
      interpret(<<-CODE).should eq(3)
        def foo
          1 + 2
        end

        foo
        CODE
    end

    it "calls a top-level method without arguments but with local vars" do
      interpret(<<-CODE).should eq(3)
        def foo
          x = 1
          y = 2
          x + y
        end

        x = foo
        x
        CODE
    end

    it "calls a top-level method with two arguments" do
      interpret(<<-CODE).should eq(3)
        def foo(x, y)
          x + y
        end

        x = foo(1, 2)
        x
        CODE
    end

    it "interprets call with default values" do
      interpret(<<-CODE).should eq(3)
        def foo(x = 1, y = 2)
          x + y
        end

        foo
        CODE
    end

    it "interprets call with named arguments" do
      interpret(<<-CODE).should eq(-15)
        def foo(x, y)
          x - y
        end

        foo(x: 10, y: 25)
        CODE
    end

    it "interprets self for primitive types" do
      interpret(<<-CODE).should eq(42)
        struct Int32
          def foo
            self
          end
        end

        42.foo
        CODE
    end

    it "interprets explicit self call for primitive types" do
      interpret(<<-CODE).should eq(42)
        struct Int32
          def foo
            self.bar
          end

          def bar
            self
          end
        end

        42.foo
        CODE
    end

    it "interprets implicit self call for pointer" do
      interpret(<<-CODE).should eq(1)
        struct Pointer(T)
          def plus1
            self + 1_i64
          end
        end

        ptr = Pointer(UInt8).malloc(1_u64)
        ptr2 = ptr.plus1
        (ptr2 - ptr)
        CODE
    end

    it "interprets call with if" do
      interpret(<<-CODE).should eq(2)
        def foo
          1 == 1 ? 2 : 3
        end

        foo
        CODE
    end

    it "does call with struct as obj" do
      interpret(<<-EXISTING, <<-CODE).should eq(3)
        struct Foo
          def initialize(@x : Int64)
          end

          def itself
            self
          end

          def x
            @x + 2_i64
          end
        end
      EXISTING
        def foo
          Foo.new(1_i64)
        end

        foo.x
      CODE
    end

    it "does call with struct as obj (2)" do
      interpret(<<-EXISTING, <<-CODE).should eq(2)
        struct Foo
          def two
            2
          end
        end
      EXISTING
        Foo.new.two
      CODE
    end

    it "discards call with struct as obj" do
      interpret(<<-EXISTING, <<-CODE).should eq(4)
        struct Foo
          def initialize(@x : Int64)
          end

          def itself
            self
          end

          def x
            @x + 2_i64
          end
        end
      EXISTING
        def foo
          Foo.new(1_i64)
        end

        foo.x
        4
      CODE
    end
  end

  context "classes" do
    it "does allocate, set instance var and get instance var" do
      interpret(<<-EXISTING, <<-CODE).should eq(42)
        class Foo
          @x = 0

          def x=(@x)
          end

          def x
            @x
          end
        end
      EXISTING
        foo = Foo.allocate
        foo.x = 42
        foo.x
      CODE
    end

    it "does constructor" do
      interpret(<<-EXISTING, <<-CODE).should eq(42)
        class Foo
          def initialize(@x : Int32)
          end

          def x
            @x
          end
        end
      EXISTING
        foo = Foo.new(42)
        foo.x
      CODE
    end

    it "interprets read instance var" do
      interpret(%(x = "hello".@c)).should eq('h'.ord)
    end

    it "discards allocate" do
      interpret(<<-EXISTING, <<-CODE).should eq(3)
        class Foo
        end
      EXISTING
        Foo.allocate
        3
      CODE
    end

    it "calls implicit class self method" do
      interpret(<<-EXISTING, <<-CODE).should eq(10)
        class Foo
          def initialize
            @x = 10
          end

          def foo
            bar
          end

          def bar
            @x
          end
        end
      EXISTING
        foo = Foo.new
        foo.foo
      CODE
    end

    it "calls explicit struct self method" do
      interpret(<<-EXISTING, <<-CODE).should eq(10)
        struct Foo
          def initialize
            @x = 10
          end

          def foo
            self.bar
          end

          def bar
            @x
          end
        end
      EXISTING
        foo = Foo.new
        foo.foo
      CODE
    end

    it "calls implicit struct self method" do
      interpret(<<-EXISTING, <<-CODE).should eq(10)
        struct Foo
          def initialize
            @x = 10
          end

          def foo
            bar
          end

          def bar
            @x
          end
        end
      EXISTING
        foo = Foo.new
        foo.foo
      CODE
    end
  end

  context "structs" do
    it "does allocate, set instance var and get instance var" do
      interpret(<<-EXISTING, <<-CODE).should eq(42)
        struct Foo
          @x = 0_i64
          @y = 0_i64

          def x=(@x)
          end

          def x
            @x
          end

          def y=(@y)
          end

          def y
            @y
          end
        end
      EXISTING
        foo = Foo.allocate
        foo.x = 22_i64
        foo.y = 20_i64
        foo.x + foo.y
      CODE
    end

    it "does constructor" do
      interpret(<<-EXISTING, <<-CODE).should eq(42)
        struct Foo
          def initialize(@x : Int32)
          end

          def x
            @x
          end
        end
      EXISTING
        foo = Foo.new(42)
        foo.x
      CODE
    end

    # it "interprets read instance var" do
    #   interpret(<<-EXISTING, <<-CODE).should eq(20)
    #     struct Foo
    #       @x = 0_i64
    #       @y = 0_i64

    #       def y=(@y)
    #       end

    #       def y
    #         @y
    #       end
    #     end
    #   EXISTING
    #     foo = Foo.allocate
    #     foo.y = 20_i64
    #     foo.@y
    #   CODE
    # end

    it "casts def body to def type" do
      interpret(<<-EXISTING, <<-CODE).should eq(1)
        struct Foo
          def foo
            return nil if 1 == 2

            self
          end
        end
      EXISTING
        value = Foo.new.foo
        value ? 1 : 2
      CODE
    end

    it "discards allocate" do
      interpret(<<-EXISTING, <<-CODE).should eq(3)
        struct Foo
        end
      EXISTING
        Foo.allocate
        3
      CODE
    end
  end

  context "tuple" do
    it "interprets tuple literal and access by known index" do
      interpret(<<-CODE).should eq(6)
        a = {1, 2, 3}
        a[0] + a[1] + a[2]
      CODE
    end

    it "interprets tuple literal of different types (1)" do
      interpret(<<-CODE).should eq(3)
        a = {1, true}
        a[0] + (a[1] ? 2 : 3)
      CODE
    end

    it "interprets tuple literal of different types (2)" do
      interpret(<<-CODE).should eq(3)
        a = {true, 1}
        a[1] + (a[0] ? 2 : 3)
      CODE
    end

    it "interprets tuple self" do
      interpret(<<-CODE).should eq(6)
        struct Tuple
          def itself
            self
          end
        end

        a = {1, 2, 3}
        b = a.itself
        b[0] + b[1] + b[2]
      CODE
    end

    it "extends sign when doing to_i32" do
      interpret(<<-CODE).should eq(-50)
        t = {-50_i16}
        exp = t[0]
        z = exp.to_i32
        CODE
    end
  end

  context "named tuple" do
    it "interprets named tuple literal and access by known index" do
      interpret(<<-CODE).should eq(6)
        a = {a: 1, b: 2, c: 3}
        a[:a] + a[:b] + a[:c]
      CODE
    end
  end

  context "blocks" do
    it "interprets simplest block" do
      interpret(<<-CODE).should eq(1)
        def foo
          yield
        end

        a = 0
        foo do
          a += 1
        end
        a
      CODE
    end

    it "interprets block with multiple yields" do
      interpret(<<-CODE).should eq(2)
        def foo
          yield
          yield
        end

        a = 0
        foo do
          a += 1
        end
        a
      CODE
    end

    it "interprets yield return value" do
      interpret(<<-CODE).should eq(1)
        def foo
          yield
        end

        z = foo do
          1
        end
        z
      CODE
    end

    it "interprets yield inside another block" do
      interpret(<<-CODE).should eq(1)
        def foo
          bar do
            yield
          end
        end

        def bar
          yield
        end

        a = 0
        foo do
          a += 1
        end
        a
      CODE
    end

    it "interprets yield inside def with arguments" do
      interpret(<<-CODE).should eq(18)
        def foo(x)
          a = yield
          a + x
        end

        a = foo(10) do
          8
        end
        a
      CODE
    end

    it "interprets yield expression" do
      interpret(<<-CODE).should eq(2)
        def foo
          yield 1
        end

        a = 1
        foo do |x|
          a += x
        end
        a
      CODE
    end

    it "interprets yield expressions" do
      interpret(<<-CODE).should eq(2 + 2*3 + 4*5)
        def foo
          yield 3, 4, 5
        end

        a = 2
        foo do |x, y, z|
          a += a * x + y * z
        end
        a
      CODE
    end

    it "discards yield expression" do
      interpret(<<-CODE).should eq(3)
        def foo
          yield 1
        end

        a = 2
        foo do
          a = 3
        end
        a
      CODE
    end

    it "yields different values to form a union" do
      interpret(<<-CODE).should eq(5)
        def foo
          yield 1
          yield 'a'
        end

        a = 2
        foo do |x|
          a +=
            case x
            in Int32
              1
            in Char
              2
            end
        end
        a
      CODE
    end

    it "returns from block" do
      interpret(<<-CODE).should eq(42)
        def foo
          baz do
            yield
          end
        end

        def baz
          yield
        end

        def bar
          foo do
            foo do
              return 42
            end
          end

          1
        end

        bar
      CODE
    end
  end

  context "casts" do
    it "casts from reference to pointer and back" do
      interpret(<<-CODE).should eq("hello")
        x = "hello"
        p = x.as(UInt8*)
        y = p.as(String)
        y
      CODE
    end
  end

  context "constants" do
    it "interprets constant literal" do
      interpret(<<-CODE).should eq(123)
        A = 123
        A
      CODE
    end

    it "interprets complex constant" do
      interpret(<<-CODE).should eq(6)
        A = begin
          a = 1
          b = 2
          a + b
        end
        A + A
      CODE
    end
  end
end

private def interpret(string, *, prelude = "primitives")
  program, return_value = interpret_full("", string, prelude: prelude)
  return_value.value
end

private def interpret(existing_code, string, *, prelude = "primitives")
  program, return_value = interpret_full(existing_code, string, prelude: prelude)
  return_value.value
end

private def interpret_full(string, *, prelude = "primitives")
  interpret_full("", string, prelude: prelude)
end

private def interpret_full(existing_code, string, *, prelude = "primitives")
  program = Crystal::Program.new
  # context = Crystal::Repl::Context.new(program, decompile: false, trace: false, stats: false)
  context = Crystal::Repl::Context.new(program, decompile: true, trace: true, stats: false)

  node = Crystal::Parser.parse(string)
  node = program.normalize(node, inside_exp: false)

  load_prelude(program, prelude, existing_code)
  interpreter = Crystal::Repl::Interpreter.new(context)
  {program, interpreter.interpret(node)}
end

private def load_prelude(program, prelude, existing_code)
  filenames = program.find_in_path(prelude)
  filenames.each do |filename|
    parser = Crystal::Parser.new File.read(filename), program.string_pool
    parser.filename = filename
    prelude_node = parser.parse
    prelude_node = program.normalize(prelude_node, inside_exp: false)

    existing_node = Crystal::Parser.parse(existing_code)
    existing_node = program.normalize(existing_node, inside_exp: false)

    program.semantic(Expressions.new([prelude_node, existing_node]))
  end
end