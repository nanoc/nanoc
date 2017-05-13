# frozen_string_literal: true

module Nanoc
  class MutableConfigView < Nanoc::ConfigView
    # Sets the value for the given attribute.
    #
    # @param [Symbol] key
    #
    # @see Hash#[]=
    def []=(key, value)
      @config[key] = value
    end
  end
end
