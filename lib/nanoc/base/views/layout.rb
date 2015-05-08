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

    def identifier
      @layout.identifier
    end

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
