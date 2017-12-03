# frozen_string_literal: true

module Nanoc::Int
  # Holds a value that might be generated lazily.
  #
  # @api private
  class LazyValue
    include Nanoc::Int::ContractsSupport

    # @param [Object, Proc] value_or_proc A value or a proc to generate the value
    def initialize(value_or_proc)
      @value = { raw: value_or_proc }
    end

    # @return [Object] The value, generated when needed
    def value
      if @value.key?(:raw)
        value = @value.delete(:raw)
        @value[:final] = value.respond_to?(:call) ? value.call : value
        @value.__nanoc_freeze_recursively if frozen?
      end
      @value[:final]
    end

    contract C::Func[C::Any => C::Any] => self
    # Returns a new lazy value that will apply the given transformation when the value is requested.
    #
    # @yield resolved value
    #
    # @return [Nanoc::Int::LazyValue]
    def map
      Nanoc::Int::LazyValue.new(-> { yield(value) })
    end

    contract C::None => self
    # @return [void]
    def freeze
      super
      @value.__nanoc_freeze_recursively unless @value[:raw]
      self
    end
  end
end
