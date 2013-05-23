# encoding: utf-8

module Nanoc

  # Represents a layout in a nanoc site. It has content, attributes, an
  # identifier and a modification time (to speed up compilation).
  class Layout < ::Nanoc::ContentPiece

    extend Nanoc::Memoization

    # Returns the type of this object. Will always return `:layout`, because
    # this is a layout. For items, this method returns `:item`.
    #
    # @api private
    #
    # @return [Symbol] :layout
    def type
      :layout
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [ type, self.identifier ]
    end

  end

end
