module Nanoc::Int
  # @api private
  class Layout < ::Nanoc::Int::Document
    def reference
      [:layout, identifier]
    end
  end
end
