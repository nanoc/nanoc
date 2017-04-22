module Nanoc::Int
  # @api private
  class Item < ::Nanoc::Int::Document
    def reference
      [:item, identifier.to_s]
    end
  end
end
