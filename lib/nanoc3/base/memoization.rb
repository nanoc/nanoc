# encoding: utf-8

module Nanoc3

  # Adds support for memoizing functions.
  module Memoization

    CACHE = {}

    # Memoizes the method with the given name. The modified method will cache
    # the results of the original method, so that calling a method twice with
    # the same arguments will short-circuit and return the cached results
    # immediately.
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
        if !CACHE.has_key?(method_name)
          CACHE[method_name] = {}
        end
        method_cache = CACHE[method_name]

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
