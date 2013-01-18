require 'benchmark'

$: << File.expand_path("../../lib", __FILE__)

if defined?(Fiber)
  require "lazing"
  module Enumerable
    alias :lazing_select :selecting
    alias :lazing_collect :collecting
  end
end
require 'reducers'
require "enumerating"

#require 'facets'

array = (1..1000000).to_a

# Test scenario:
#  - filter out even numbers
#  - square them
#  - grab the first thousand

printf "%-30s", "IMPLEMENTATION"
printf "%12s", "take(10)"
printf "%12s", "take(100)"
printf "%12s", "take(10000)"
printf "%12s", "to_a"
puts ""

def measure(&block)
  begin
    printf "%12.5f", Benchmark.realtime(&block)
  rescue
    printf "%12s", "n/a"
  end
end

def benchmark(description, control_result = nil)
  result = nil
  printf "%-30s", description
  measure { yield.take(10).to_a }
  measure { yield.take(100).to_a }
  measure { result = yield.take(10000).to_a }
  measure { yield.to_a }
  puts ""
  unless control_result.nil? || result == control_result
    raise "unexpected result from '#{description}'"
  end
  result
end

@control = benchmark "conventional (eager)" do
  array.select { |x| x.even? }.collect { |x| x*x }
end

benchmark "enumerating", @control do
  array.selecting { |x| x.even? }.collecting { |x| x*x }
end

if defined?(Fiber)
  benchmark "lazing", @control do
    array.lazing_select { |x| x.even? }.lazing_collect { |x| x*x }
  end
end

if array.respond_to?(:lazy)
  benchmark "ruby2 Enumerable#lazy", @control do
    array.lazy.select { |x| x.even? }.lazy.collect { |x| x*x }
  end
end

# benchmark "facets Enumerable#defer", @control do
#   array.defer.select { |x| x.even? }.collect { |x| x*x }
# end

benchmark "reducible" , @control do
  array.lazy2.select{|x| x.even?}.map{|x| x*x}
end
puts "\nCOLLECT THEN SELECT BENCHMARKS\n"
@control = benchmark "conventional (eager)" do
  array.collect{|x| x*x}.select{|x| x % 25 == 0}.select{ |x| x.even? }
end

benchmark "enumerating", @control do
  array.collecting { |x| x*x }.selecting{|x| x % 25 == 0}.selecting { |x| x.even? }
end

if defined?(Fiber)
  benchmark "lazing", @control do
    array.lazing_collect { |x| x*x }.lazing_select{|x| x % 25 == 0}.lazing_select { |x| x.even? }
  end
end

if array.respond_to?(:lazy)
  benchmark "ruby2 Enumerable#lazy", @control do
    array.lazy.collect { |x| x*x }.select{|x| x % 25 == 0}.select { |x| x.even? }.lazy
  end
end

# benchmark "facets Enumerable#defer", @control do
#   array.defer.select { |x| x.even? }.collect { |x| x*x }
# end

benchmark "reducible" , @control do
  array.lazy2.map{|x| x*x}.select{|x| x % 25 == 0}.select{|x| x.even?}
end
