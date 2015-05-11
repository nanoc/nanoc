# encoding: utf-8

module Nanoc
  class LayoutView
    # @api private
    def initialize(layout)
      @layout = layout
    end

    # @api private
    def unwrap
      @layout
    end

    # @see Object#==
    def ==(other)
      identifier == other.identifier
    end
    alias_method :eql?, :==

    # @see Object#hash
    def hash
      self.class.hash ^ identifier.hash
    end

    # @return [Nanoc::Identifier]
    def identifier
      @layout.identifier
    end

    # @see Hash#[]
    def [](key)
      @layout[key]
    end

    # @api private
    def reference
      @layout.reference
    end

    # @api private
    def raw_content
      @layout.raw_content
    end
  end
end
