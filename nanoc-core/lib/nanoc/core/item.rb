# frozen_string_literal: true

module Nanoc
  module Core
    class Item < ::Nanoc::Core::Document
      def reference
        @_reference ||= "item:#{identifier}"
      end

      def identifier=(new_identifier)
        super(new_identifier)

        # Invalidate memoization cache
        @_reference = nil
      end
    end
  end
end
