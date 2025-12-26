# frozen_string_literal: true

module Nanoc
  module Core
    class BasicItemRepView < ::Nanoc::Core::View
      # @api private
      def initialize(item_rep, context)
        super(context)
        @item_rep = item_rep
      end

      # @abstract
      def item_view_class
        Nanoc::Core::BasicItemView
      end

      # @api private
      def _unwrap
        @item_rep
      end

      # @see Object#==
      def ==(other)
        other.respond_to?(:item) && other.respond_to?(:name) && item == other.item && name == other.name
      end

      # @see Object#eql?
      def eql?(other)
        other.is_a?(self.class) &&
          item.eql?(other.item) &&
          name.eql?(other.name)
      end

      # @see Object#hash
      def hash
        [self.class, item.identifier, name].hash
      end

      # @return [Symbol]
      def name
        @item_rep.name
      end

      def snapshot?(name)
        @context.dependency_tracker.bounce(_unwrap.item, compiled_content: true)
        @item_rep.snapshot?(name)
      end

      # Returns the item rep’s path, as used when being linked to. It starts
      # with a slash and it is relative to the output directory. It does not
      # include the path to the output directory. It will not include the
      # filename if the filename is an index filename.
      #
      # @param [Symbol] snapshot The snapshot for which the path should be
      #   returned.
      #
      # @return [String] The item rep’s path.
      def path(snapshot: :last)
        @context.dependency_tracker.bounce(_unwrap.item, path: true)
        @item_rep.path(snapshot:)
      end

      # Returns the item that this item rep belongs to.
      #
      # @return [Nanoc::Core::CompilationItemView]
      def item
        item_view_class.new(@item_rep.item, @context)
      end

      # @api private
      def binary?
        snapshot_def = _unwrap.snapshot_defs.find { |sd| sd.name == :last }
        raise Nanoc::Core::Errors::NoSuchSnapshot.new(_unwrap, :last) if snapshot_def.nil?

        snapshot_def.binary?
      end

      def inspect
        "<#{self.class} item.identifier=#{item.identifier} name=#{name}>"
      end
    end
  end
end
