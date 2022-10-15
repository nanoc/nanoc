# frozen_string_literal: true

module Nanoc
  module Core
    class Layout < ::Nanoc::Core::Document
      def reference
        @_reference ||= "layout:#{identifier}"
      end
    end
  end
end
