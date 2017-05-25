# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Layout < ::Nanoc::Int::Document
    def reference
      [:layout, identifier.to_s]
    end
  end
end
