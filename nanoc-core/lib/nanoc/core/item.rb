# frozen_string_literal: true

module Nanoc
  module Core
    class Item < ::Nanoc::Core::Document
      def reference
        "item:#{identifier}"
      end
    end
  end
end
