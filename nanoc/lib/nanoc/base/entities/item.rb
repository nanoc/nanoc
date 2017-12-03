# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Item < ::Nanoc::Int::Document
    def reference
      "item:#{identifier}"
    end
  end
end
