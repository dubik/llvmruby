require 'test/unit'
$:.unshift File.dirname(__FILE__) + "/../ext"
require 'llvm'

include LLVM

class MyOwnTests < Test::Unit::TestCase
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
      assert_equal test_num, ExecutionEngine.run_function(function, test_num)
    }
  end

  def test_ints32
    function = create_function(Type::Int32Ty)
    # TODO add max ints
    [0, 5, 134, -5, -134].each {|test_num|
      assert_equal test_num, ExecutionEngine.run_function(function, test_num)
    }
  end

  def test_float
    function = create_function(Type::FloatTy)
    [0.0, 0.1, 0.5, 100.4, -0.1, -0.5, -100.4].each {|test_num|
      assert_in_delta test_num, ExecutionEngine.run_function(function, test_num), 0.00001
    }
  end

  def test_double
    function = create_function(Type::DoubleTy)
    [0.0, 0.1, 0.5, 100.4, -0.1, -0.5, -100.4].each {|test_num|
      assert_equal test_num, ExecutionEngine.run_function(function, test_num)
    }
  end
end