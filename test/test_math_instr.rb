require 'test/unit'
$:.unshift File.dirname(__FILE__) + "/../ext"
require 'llvm'

include LLVM

class MathInstrTest < Test::Unit::TestCase
  def create_function(type, instr)
    mainModule = LLVM::Module.new("main")
    functionType = Type.function(type, [type, type])
    function = mainModule.get_or_insert_function("test", functionType)
    function.arguments[0].name = "op1"
    function.arguments[1].name = "op2"    
    functionBlock = function.create_block.builder
    ret = functionBlock.bin_op(instr, function.arguments[0], function.arguments[1])
    functionBlock.return(ret)
    
    ExecutionEngine.get(mainModule)
    return function
  end
  
  def test_fdiv
    function = create_function(Type::DoubleTy, Instruction::FDiv)

    assert_equal 0.5, ExecutionEngine.run_function_auto_args(function, 1.1, 2.2)
  end
  
  def test_frem
    function = create_function(Type::DoubleTy, Instruction::FRem)

    assert_equal 2.0, ExecutionEngine.run_function_auto_args(function, 10.0, 4.0)
  end

  def test_fsub
    function = create_function(Type::DoubleTy, Instruction::FSub)

    assert_equal 5.5, ExecutionEngine.run_function_auto_args(function, 10.0, 4.5)
  end

  def test_fadd
    function = create_function(Type::DoubleTy, Instruction::FAdd)

    assert_equal 14.5, ExecutionEngine.run_function_auto_args(function, 10.0, 4.5)
  end

  def test_fmul
    function = create_function(Type::DoubleTy, Instruction::FMul)

    assert_equal 45.0, ExecutionEngine.run_function_auto_args(function, 10.0, 4.5)
  end
end