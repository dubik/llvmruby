require 'test/unit'
$:.unshift File.dirname(__FILE__) + "/../ext"
require 'llvm'

include LLVM

class ArgumentsTest < Test::Unit::TestCase
  def create_function(type)
    #
    #  type circle_area(type k)
    #  return k
    #
    mainModule = LLVM::Module.new("main")
    functionType = Type.function(type, [type])
    function = mainModule.get_or_insert_function("circle_area", functionType)
    function.arguments[0].name ="k"
    functionBlock = function.create_block.builder
    functionBlock.return(function.arguments[0])
    ExecutionEngine.get(mainModule)
        
    return function
  end
  
  
  def test_ints64
    function = create_function(Type::Int64Ty)
    # TODO add max ints
    [0, 1, 1000, -1, -1000].each {|test_num|
      assert_equal test_num, ExecutionEngine.run_function_auto_args(function, test_num)
    }
  end

  def test_ints32
    function = create_function(Type::Int32Ty)
    # TODO add max ints
    [0, 5, 134, -5, -134].each {|test_num|
      assert_equal test_num, ExecutionEngine.run_function_auto_args(function, test_num)
    }
  end

  def test_float
    function = create_function(Type::FloatTy)
    [0.0, 0.1, 0.5, 100.4, -0.1, -0.5, -100.4].each {|test_num|
      assert_in_delta test_num, ExecutionEngine.run_function_auto_args(function, test_num), 0.00001
    }
  end

  def test_double
    function = create_function(Type::DoubleTy)
    [0.0, 0.1, 0.5, 100.4, -0.1, -0.5, -100.4].each {|test_num|
      assert_equal test_num, ExecutionEngine.run_function_auto_args(function, test_num)
    }
  end


  def test_char_pointer
=begin
    struct RBasic {
        unsigned long flags;
        unsigned long klass;
     };

     struct RString {
         struct RBasic basic;
         long len;
         char *ptr;
      };

      long len(struct RString * ptr)
      {
          return ptr->len;
      }
=end

    assembly = <<-EOF
    ; ModuleID = '/tmp/webcompile/_22990_0.bc'
    target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
    target triple = "x86_64-unknown-linux-gnu"

    %struct.RBasic = type { i64, i64 }
    %struct.RString = type { %struct.RBasic, i64, i8* }

    define i64 @len(%struct.RString* nocapture %ptr) nounwind readonly {
      %1 = getelementptr inbounds %struct.RString* %ptr, i64 0, i32 1
      %2 = load i64* %1, align 8, !tbaa !0
      ret i64 %2
    }

    !0 = metadata !{metadata !"long", metadata !1}
    !1 = metadata !{metadata !"omnipotent char", metadata !2}
    !2 = metadata !{metadata !"Simple C/C++ TBAA", null}
    EOF

    mainModule = LLVM::Module.read_assembly(assembly)
    function = mainModule.get_function("len")
    ExecutionEngine.get(mainModule)
    ["h", "he", "hel"].each {|test_str|
      assert_equal test_str.length, ExecutionEngine.run_function_auto_args(function, test_str)
    }
  end

  def test_bool
    function = create_function(Type::Int8Ty)
    assert_equal 1, ExecutionEngine.run_function_auto_args(function, true)
    assert_equal 0, ExecutionEngine.run_function_auto_args(function, false)
  end

  def test_nil
    function = create_function(Type::MACHINE_WORD)
    assert_equal 0, ExecutionEngine.run_function_auto_args(function, nil)
  end
  
  def test_pointer_nil
    function = create_function(Type.pointer(Type::Int8Ty))
    assert_equal 0, ExecutionEngine.run_function_auto_args(function, nil)
  end
end