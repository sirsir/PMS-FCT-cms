module Enumerable
  def cartprod(*args)
    return self if [] == args
    b = args.shift
    result = []
    block_size = 1000

    estimated_result_length = self.length * b.length
    raise "Cartesian product exceed limitation (#{cartprod_limit}). Estimated result will have #{estimated_result_length} elements." if estimated_result_length > cartprod_limit

    0.step(self.length-1, block_size) do |i|
      self[i..(i+block_size-1)].each do |n|
        b.cartprod(*args).each do |a|
          result << (n.kind_of?(Array)? n: [n]) + (a.kind_of?(Array)? a: [a])
        end
      end
    end
      
    result
  end

  def cartprod_limit
    0x1fffff
  end
end

def cartprod(*args)
  args.shift.cartprod(args)
end