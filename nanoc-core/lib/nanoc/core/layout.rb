# frozen_string_literal: true

module Nanoc
  module Core
    class Layout < ::Nanoc::Core::Document
      def reference
        @_reference ||= "layout:#{identifier}"
      end

      def identifier=(new_identifier)
        super

        # Invalidate memoization cache
        @_reference = nil
      end
    end
  end
end
