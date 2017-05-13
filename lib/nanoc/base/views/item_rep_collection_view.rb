# frozen_string_literal: true

module Nanoc
  class ItemRepCollectionView < ::Nanoc::View
    include Enumerable

    class NoSuchItemRepError < ::Nanoc::Error
      def initialize(rep_name)
        super("No rep named #{rep_name.inspect} was found.")
      end
    end

    # @api private
    def initialize(item_reps, context)
      super(context)
      @item_reps = item_reps
    end

    # @api private
    def unwrap
      @item_reps
    end

    # @api private
    def view_class
      Nanoc::ItemRepView
    end

    def to_ary
      @item_reps.map { |ir| view_class.new(ir, @context) }
    end

    # Calls the given block once for each item rep, passing that item rep as a parameter.
    #
    # @yieldparam [Object] item rep view
    #
    # @yieldreturn [void]
    #
    # @return [self]
    def each
      @item_reps.each { |ir| yield view_class.new(ir, @context) }
      self
    end

    # @return [Integer]
    def size
      @item_reps.size
    end

    # Return the item rep with the given name, or nil if no item rep exists.
    #
    # @param [Symbol] rep_name
    #
    # @return [nil] if no item rep with the given name was found
    #
    # @return [Nanoc::ItemRepView] if an item rep with the given name was found
    def [](rep_name)
      case rep_name
      when Symbol
        res = @item_reps.find { |ir| ir.name == rep_name }
        res && view_class.new(res, @context)
      when Integer
        raise ArgumentError, "expected ItemRepCollectionView#[] to be called with a symbol (you likely want `.reps[:default]` rather than `.reps[#{rep_name}]`)"
      else
        raise ArgumentError, 'expected ItemRepCollectionView#[] to be called with a symbol'
      end
    end

    # Return the item rep with the given name, or raises an exception if there
    # is no rep with the given name.
    #
    # @param [Symbol] rep_name
    #
    # @return [Nanoc::ItemRepView]
    #
    # @raise if no rep was found
    def fetch(rep_name)
      res = @item_reps.find { |ir| ir.name == rep_name }
      if res
        view_class.new(res, @context)
      else
        raise NoSuchItemRepError.new(rep_name)
      end
    end
  end
end
