# encoding: utf-8

module Nanoc3

  # Adds support for memoizing functions.
  #
  # @since 3.2.0
  module Memoization

    CACHE = {}

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
    #       extend Nanoc3::Memoization
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
      # Alias
      original_method_name = '__nonmemoized_' + method_name.to_s
      alias_method original_method_name, method_name

      # Redefine
      define_method(method_name) do |*args|
        # Get method-specific cache
        key = [ self, method_name ]
        if !CACHE.has_key?(key)
          CACHE[key] = {}
        end
        method_cache = CACHE[key]

        # Recalculate if necessary
        if !method_cache.has_key?(args)
          result = send(original_method_name, *args)
          method_cache[args] = result
        end

        # Done
        method_cache[args]
      end
    end

  end

end
