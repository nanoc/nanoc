module Nanoc::Int
  # Holds a value that might be generated lazily.
  #
  # @api private
  class LazyValue
    # @param [Object, Proc] value_or_proc A value or a proc to generate the value
    def initialize(value_or_proc)
      @value = { raw: value_or_proc }
    end

    # @return [Object] The value, generated when needed
    def value
      if @value.key?(:raw)
        value = @value.delete(:raw)
        @value[:final] = transform(value.respond_to?(:call) ? value.call : value)
        @value.__nanoc_freeze_recursively if frozen?
      end
      @value[:final]
    end

    # @param [Object, Proc] value A value to be transformed
    #
    # @return [Object] The original value (override for more specific behavior)
    def transform(value)
      value
    end

    # @return [void]
    def freeze
      super
      @value.__nanoc_freeze_recursively unless @value[:raw]
    end
  end
end
