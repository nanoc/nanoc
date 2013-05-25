# encoding: utf-8

module Nanoc

  # Represents a layout in a nanoc site. It has content, attributes, an
  # identifier and a modification time (to speed up compilation).
  class Layout < ::Nanoc::Document

    # Returns the type of this object. Will always return `:layout`, because
    # this is a layout. For items, this method returns `:item`.
    #
    # @api private
    #
    # @return [Symbol] :layout
    def type
      :layout
    end

  end

end
