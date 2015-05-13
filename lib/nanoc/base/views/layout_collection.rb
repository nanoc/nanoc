# encoding: utf-8

module Nanoc
  class LayoutCollectionView
    include Enumerable

    # @api private
    def initialize(layouts)
      @layouts = layouts
    end

    # @api private
    def unwrap
      @layouts
    end

    # @api private
    def view_class
      Nanoc::LayoutView
    end

    # Calls the given block once for each layout, passing that layout as a parameter.
    #
    # @yieldparam [Nanoc::LayoutView] layout
    #
    # @yieldreturn [void]
    def each
      @layouts.each { |l| yield view_class.new(l) }
      self
    end

    # @overload [](string)
    #
    #   Finds the item whose identifier matches the given string.
    #
    #   If the glob syntax is enabled, the string can be a glob, in which case
    #   this method finds the first item that matches the given glob.
    #
    #   @param [String] string
    #
    #   @return [nil] if no item matches the string
    #
    #   @return [Nanoc::ItemView] if an item was found
    #
    # @overload [](regex)
    #
    #   Finds the item whose identifier matches the given regular expression.
    #
    #   @param [Regex] regex
    #
    #   @return [nil] if no item matches the regex
    #
    #   @return [Nanoc::ItemView] if an item was found
    def [](arg)
      layout = @layouts.find { |l| l.identifier == arg }
      return view_class.new(layout) if layout

      # FIXME: this should only work if globs are enabled
      pat = Nanoc::Int::Pattern.from(arg)
      layout = @layouts.find { |l| pat.match?(l.identifier) }
      return view_class.new(layout) if layout

      nil
    end
  end
end
