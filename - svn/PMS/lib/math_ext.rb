module Math
  #   Math.gcd(a, b) -> integer
  #
  # Greatest Common Divisor
  # 
  # The largest positive integer that divides the numbers without a remainder. For example, the GCD of 8 and 12 is 4.
  #
  # Divisor of 1000 are:
  #   1, 2, 4, 5, 8, 10, 20, 25, 40, 50, 100, 125, 200, 250, 500, 1000
  # and the divisor of 128 are:
  #   1, 2, 4, 8, 16, 32, 64, 128
  # Common divisors of 1000 and 128 are simply the numbers that are in both lists:
  #   1, 2, 4, 8
  # So the most common divisor of 1000 and 128 is the largest one of those: 8
  # 
  #   Math.gcd(1000, 128) #=> 8
  def self.gcd(a, b)
    values = [a, b]

    remain = values.min

    while remain != 0
      dividend = values.max
      divisor  = values.min

      quotient = dividend / divisor
      remain = dividend % divisor
    
      values.delete(dividend)
      values << remain
    end
    
    values.delete(0)
    values.min
  end

  #   Math.lcm(a, b) -> integer
  #
  # Least Common Multiple
  #
  # The LCM is the smallest positive rational number that is an integer multiple of both a and b
  #
  # Multiples of 4 are:
  #   4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, ...
  # and the multiples of 6 are:
  #   6, 12, 18, 24, 30, 36, 42, 48, ...
  # Common multiples of 4 and 6 are simply the numbers that are in both lists:
  #   12, 24, 36, 48, ....
  # So the least common multiple of 4 and 6 is the smallest one of those: 12
  #
  #   Math.lcm(4, 6) #=> 12
  def self.lcm(a, b)
    (a*b)/gcd(a, b)
  end
  
  #   Math.prime_numbers(options) -> an_array
  #
  # A prime number (or a prime) is a natural number that has exactly two
  # distinct natural number divisors: 1 and itself. The smallest twenty-five
  # prime numbers (all the prime numbers under 100) are:
  #   2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
  #   53, 59, 61, 67, 71, 73, 79, 83, 89, 97
  #
  #   Math.prime_numbers                            #=> [2, 3, 5, 7, ..., 89, 97]
  #   Math.prime_numbers(:min => 70)                #=> [71, 73, 79, 83, 89, 97]
  #   Math.prime_numbers(:max => 20)                #=> [2, 3, 5, 7, 11, 13, 17, 19]
  #   Math.prime_numbers(:min => 100, :max => 200)  #=> [101, 103, ..., 197, 199]
  def self.prime_numbers(options = {})
    options = {
        :min => 1,
        :max => 100
      }.merge(options)
    
    min = options[:min].to_i
    max = options[:max].to_i
    
    @@prime_numbers ||= {}
    @@prime_numbers[min] ||= {}
    @@prime_numbers[min][max] ||= (min..max).to_a.select{|i| i unless ('1' * i) =~/^1$|^(11+?)\1+$/ }
  end
end
