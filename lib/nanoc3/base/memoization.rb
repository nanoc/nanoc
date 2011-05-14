# encoding: utf-8

module Nanoc3

  # TODO document
  module Memoization

    CACHE = {}

    # TODO document
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
