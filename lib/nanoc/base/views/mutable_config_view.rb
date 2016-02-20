module Nanoc
  class MutableConfigView < Nanoc::ConfigView
    # @api private
    attr_reader :updated

    def initialize(*args)
      super
      @updated = @config.dup
    end

    # Sets the value for the given attribute.
    #
    # @param [Symbol] key
    #
    # @see Hash#[]=
    def []=(key, value)
      @updated[key] = value
    end
  end
end
