begin
a = [
    ['A1','A2','A3','A4'],
    ['B1','B2'],
    ['C1','C2','C3','C4']
  ]

  a1 = nil

  a.each do |x|
    a1 = a1.nil? ? x : a1.cartprod(x)
  end

  a2 = a1.cartprod(['-'])
  a2 = a2.cartprod(a1)

  line ="="*20
  puts "#{line} Data 1 #{line}"
  a1.each {|x| puts x.join }
  puts "#{line} Data 2 #{line}"
  a2.each {|x| puts x.join }
end
