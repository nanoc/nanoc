module Nanoc::Int
  # @api private
  class Item < ::Nanoc::Int::Document
    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item, identifier.to_s]
    end
  end
end
