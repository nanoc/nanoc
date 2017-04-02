require 'weakref'

module Nanoc::Int
  # Adds support for memoizing functions.
  #
  # @api private
  module Memoization
    class Value
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    NONE = Object.new

    # Memoizes the method with the given name. The modified method will cache
    # the results of the original method, so that calling a method twice with
    # the same arguments will short-circuit and return the cached results
    # immediately.
    #
    # Memoization assumes that the current object as well as the function
    # arguments are immutable. Mutating the object or the arguments will not
    # cause memoized methods to recalculate their results. There is no way to
    # un-memoize a result, and calculation results will remain in memory even
    # if they are no longer needed.
    #
    # @example A fast fib function due to memoization
    #
    #     class FibFast
    #
    #       extend Nanoc::Int::Memoization
    #
    #       def run(n)
    #         if n == 0
    #           0
    #         elsif n == 1
    #           1
    #         else
    #           run(n-1) + run(n-2)
    #         end
    #       end
    #       memoize :run
    #
    #     end
    #
    # @param [Symbol, String] method_name The name of the method to memoize
    #
    # @return [void]
    def memoize(method_name)
      original_method_name = '__nonmemoized_' + method_name.to_s
      alias_method original_method_name, method_name

      instance_cache = Hash.new { |hash, key| hash[key] = {} }

      define_method(method_name) do |*args|
        instance_method_cache = instance_cache[self]

        value = NONE
        if instance_method_cache.key?(args)
          object = instance_method_cache[args].object
          value = object ? object.value : NONE
        end

        counter_label = is_a?(Class) ? "#{self}.#{method_name}" : "#{self.class}##{method_name}"
        if value.equal?(NONE)
          Nanoc::Int::NotificationCenter.post(:memoization_miss, counter_label)
          send(original_method_name, *args).tap do |r|
            instance_method_cache[args] = Ref::SoftReference.new(Value.new(r))
          end
        else
          Nanoc::Int::NotificationCenter.post(:memoization_hit, counter_label)
          value
        end
      end
    end
    alias memoized memoize
  end
end
