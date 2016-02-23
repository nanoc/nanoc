module Nanoc
  class MutableConfigView < Nanoc::ConfigView
    # @api private
    def initialize(config, context)
      super(Nanoc::Int::Configuration::Mutator.for(config.wrapped), context)
    end

    # Sets the value for the given attribute.
    #
    # @param [Symbol] key
    #
    # @see Hash#[]=
    def []=(key, value)
      unwrap[key] = value
    end
  end
end
