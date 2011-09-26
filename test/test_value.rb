require 'test/unit'
require 'llvm'

include LLVM

class ValueTests < Test::Unit::TestCase

  def setup
    @assembly=<<-EOF
    ; ModuleID = '/tmp/webcompile/_14635_0.bc'
    target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"
    target triple = "x86_64-unknown-linux-gnu"

    @CONST_PI = constant float 0x400921FA00000000, align 4

    define float @circle_area(float %radius) nounwind readnone {
      %1 = fmul float %radius, 0x400921FA00000000
      %2 = fmul float %1, %radius
      ret float %2
    }

    define i32 @add_42(i32 %x) nounwind readnone {
      %1 = add nsw i32 %x, 42
      ret i32 %1
    }
    EOF

    @m = LLVM::Module.read_assembly(@assembly)
  end

  def test_check_value_is_constant
    add42 = @m.get_function("add_42")
    assert(add42)
    ins = add42.get_basic_block_list[0].get_instruction_list
    add_ins = ins[0]
    assert_equal(false,add_ins.get_operand(0).is_constant())
    assert_equal(true,add_ins.get_operand(1).is_constant())
  end

  def test_get_integer_constant_values
    add42 = @m.get_function("add_42")
    assert(add42)
    ins = add42.get_basic_block_list[0].get_instruction_list
    add_ins = ins[0]
    assert(add_ins.get_operand(1).is_constant())
    assert(add_ins.get_operand(1).is_int_constant())
    assert_equal(42,add_ins.get_operand(1).get_int_constant_value())
  end

  def test_get_float_constant_values
    circle_area = @m.get_function("circle_area")
    assert(circle_area)
    ins = circle_area.get_basic_block_list[0].get_instruction_list
    add_ins = ins[0]
    assert_equal(false,add_ins.get_operand(0).is_constant())
    assert_equal(true,add_ins.get_operand(1).is_constant())
    assert_equal(true,add_ins.get_operand(1).is_float_constant())
    assert_in_delta(3.14159, add_ins.get_operand(1).get_float_constant_value(), 2 ** -20)
  end

end

