require 'llvm'
include LLVM
include RubyInternals

class Builder
  include RubyHelpers
end

m = LLVM::Module.new('ruby_bindings_examples')
ExecutionEngine.get(m)

def ftype(ret_type, arg_types)
  Type.function(ret_type, arg_types)
end

rb_ary_new = m.external_function('rb_ary_new', ftype(VALUE, []))
rb_to_id = m.external_function('rb_to_id', ftype(VALUE, [VALUE]))
rb_ivar_get = m.external_function('rb_ivar_get', ftype(VALUE, [VALUE, ID]))
rb_ivar_set = m.external_function('rb_ivar_set', ftype(VALUE, [VALUE, ID, VALUE]))

class TestClass
  def initialize
    @shaka = 'khan'
  end
end

test_instance = TestClass.new

# take an object and an instance variable symbol, return value of instance variable
type = Type.function(VALUE, [VALUE, VALUE])
f = m.get_or_insert_function('shakula', type)
obj, ivar_sym = f.arguments
b = f.create_block.builder
new_ary = b.create_call(rb_ary_new)
ivar_id = b.create_call(rb_to_id, ivar_sym)
ret_val = b.create_call(rb_ivar_get, obj, ivar_id)
b.create_return(ret_val)
ret = ExecutionEngine.run_function(f, test_instance, :@shaka)
puts "get instance variable @shaka: #{ret.inspect}"

# Return the last element of an array
type = Type.function(Type::Int64Ty, [Type::Int64Ty])
f = m.get_or_insert_function('last', type)
b = f.create_block.builder
ary = f.arguments.first
len = b.alen(ary)
idx = b.sub(len, 1.llvm)
ret = b.aref(ary, idx)
b.create_return(ret)
last = f

# Swap the first and last elements of an array (in place)
type = Type.function(Type::Int64Ty, [Type::Int64Ty])
f = m.get_or_insert_function('swap', type)
b = f.create_block.builder
ary = f.arguments.first
len = b.alen(ary)
last_idx = b.sub(len, 1.llvm)
idx_x = 0.llvm
idx_y = b.sub(last_idx, idx_x)
x = b.aref(ary, idx_x)
y = b.aref(ary, idx_y)
b.aset(ary, idx_x, y)
b.aset(ary, idx_y, x)
b.create_return(ary)
swap = f

# Add 1 to every array element (in place)
type = Type.function(Type::Int64Ty, [Type::Int64Ty])
f = m.get_or_insert_function('add1', type)
ary = f.arguments.first

entry_block = f.create_block
loop_block = f.create_block
exit_block = f.create_block

b = entry_block.builder
len = b.alen(ary)
cmp = b.icmp_eq(0.llvm, len)
b.create_cond_br(cmp, exit_block, loop_block)

b = loop_block.builder
idx = b.create_phi(Type::Int64Ty)
idx.add_incoming(0.llvm, entry_block)
next_idx = b.add(1.llvm, idx)
idx.add_incoming(next_idx, loop_block)
v = b.fix2int(b.aref(ary, idx))
v1 = b.add(1.llvm, v)
b.aset(ary, idx, b.num2fix(v1))
cmp = b.icmp_ult(next_idx, len)
b.create_cond_br(cmp, loop_block, exit_block)

b = exit_block.builder
b.create_return(ary)
add1 = f

ret = ExecutionEngine.run_function(add1, [1,2,3,4,5])
puts "add1: #{ret.inspect}"

# Add 1 to every array element (in place)
type = Type.function(Type::Int64Ty, [Type::Int64Ty])
f = m.get_or_insert_function('reverse', type)
ary = f.arguments.first

entry_block = f.create_block
loop_block = f.create_block
exit_block = f.create_block

b = entry_block.builder
len = b.alen(ary)
half_len = b.udiv(len, 2.llvm)
last_idx = b.sub(len, 1.llvm)
cmp = b.icmp_eq(0.llvm, len)
b.create_cond_br(cmp, exit_block, loop_block)

b = loop_block.builder
idx = b.create_phi(Type::Int64Ty)
idx.add_incoming(0.llvm, entry_block)
next_idx = b.add(1.llvm, idx)
idx.add_incoming(next_idx, loop_block)

# do the swap
idx_x = idx
idx_y = b.sub(last_idx, idx)
x = b.aref(ary, idx_x)
y = b.aref(ary, idx_y)
b.aset(ary, idx_x, y)
b.aset(ary, idx_y, x)

cmp = b.icmp_ult(next_idx, half_len)
b.create_cond_br(cmp, loop_block, exit_block)

b = exit_block.builder
b.create_return(ary)
reverse = f

ret = ExecutionEngine.run_function(reverse, [1,2,3,4,5])
puts "reverse: #{ret.inspect}"

# Run some benchmarks
if false
def ruby_reverse(ary)
  half_len = ary.length/2 
  last_idx = ary.length-1
  for x in 0...half_len
    y = last_idx-x
    ary[x], ary[y] = ary[y], ary[x]
  end
  ary
end

ret = ruby_reverse([1,2,3,4,5])
puts "ruby_reverse: #{ret.inspect}"
    
require 'benchmark'
n = 10
ary = Array.new(100000) {|x| x}
Benchmark.bm do |x|
  x.report { n.times { ruby_reverse(ary) } }
  x.report { n.times { ExecutionEngine.run_function(reverse, ary) } }
end
end
