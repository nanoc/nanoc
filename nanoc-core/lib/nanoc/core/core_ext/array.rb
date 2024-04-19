# frozen_string_literal: true

module Nanoc
  module Core
    module CoreExt
      module ArrayExtensions
        # Returns a new array where all items' keys are recursively converted to
        # symbols by calling {Nanoc::ArrayExtensions#__nanoc_symbolize_keys_recursively} or
        # {Nanoc::HashExtensions#__nanoc_symbolize_keys_recursively}.
        #
        # @return [Array] The converted array
        def __nanoc_symbolize_keys_recursively
          map do |element|
            if element.respond_to?(:__nanoc_symbolize_keys_recursively)
              element.__nanoc_symbolize_keys_recursively
            else
              element
            end
          end
        end

        def __nanoc_stringify_keys_recursively
          map do |element|
            if element.respond_to?(:__nanoc_stringify_keys_recursively)
              element.__nanoc_stringify_keys_recursively
            else
              element
            end
          end
        end

        # Freezes the contents of the array, as well as all array elements. The
        # array elements will be frozen using {#__nanoc_freeze_recursively} if they respond
        # to that message, or #freeze if they do not.
        #
        # @see Hash#__nanoc_freeze_recursively
        #
        # @return [void]
        def __nanoc_freeze_recursively
          return if frozen?

          freeze
          each do |value|
            if value.respond_to?(:__nanoc_freeze_recursively)
              value.__nanoc_freeze_recursively
            else
              value.freeze
            end
          end
        end
      end
    end
  end
end

class Array
  include Nanoc::Core::CoreExt::ArrayExtensions
end
