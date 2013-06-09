# encoding: utf-8

module Nanoc

  # Represents a compileable item in a site. It has content and attributes, as
  # well as an identifier (which starts and ends with a slash). It can also
  # store the modification time to speed up compilation.
  class Item < Document

    # Returns the type of this object. Will always return `:item`, because
    # this is an item. For layouts, this method returns `:layout`.
    #
    # @api private
    #
    # @return [Symbol] :item
    def type
      :item
    end

    # @api private
    def forced_outdated=(bool)
      @forced_outdated = bool
    end

    # @api private
    def forced_outdated?
      @forced_outdated || false
    end

  end

end
