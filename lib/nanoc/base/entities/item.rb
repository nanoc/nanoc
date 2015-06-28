module Nanoc::Int
  # @api private
  class Item < ::Nanoc::Int::Document
    # @return [Array<Nanoc::Int::ItemRep>] This item’s list of item reps
    attr_reader :reps

    # @return [Nanoc::Int::Item, nil] The parent item of this item. This can be
    #   nil even for non-root items.
    attr_accessor :parent

    # @return [Array<Nanoc::Int::Item>] The child items of this item
    attr_accessor :children

    # @see Document#initialize
    def initialize(content, attributes, identifier)
      super

      @parent = nil
      @children = []
      @reps = []
      @forced_outdated_status = ForcedOutdatedStatus.new
    end

    def freeze
      super
      @children.freeze
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [:item, identifier.to_s]
    end

    # Hack to allow a frozen item to still have modifiable frozen status.
    #
    # FIXME: Remove this.
    class ForcedOutdatedStatus
      attr_accessor :bool

      def initialize
        @bool = false
      end

      def freeze
      end
    end

    # @api private
    def forced_outdated=(bool)
      @forced_outdated_status.bool = bool
    end

    # @api private
    def forced_outdated?
      @forced_outdated_status.bool
    end
  end
end
