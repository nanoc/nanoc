module Nanoc::Int
  # @api private
  class Item < ::Nanoc::Int::Document
    # @see Document#initialize
    def initialize(content, attributes, identifier)
      super
    end

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
