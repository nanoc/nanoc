# frozen_string_literal: true

module Nanoc
  module Core
    class MutableConfigView < Nanoc::Core::ConfigView
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
end
