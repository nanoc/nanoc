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
    #   Finds the layout whose identifier matches the given string.
    #
    #   If the glob syntax is enabled, the string can be a glob, in which case
    #   this method finds the first layout that matches the given glob.
    #
    #   @param [String] string
    #
    #   @return [nil] if no layout matches the string
    #
    #   @return [Nanoc::LayoutView] if an layout was found
    #
    # @overload [](regex)
    #
    #   Finds the layout whose identifier matches the given regular expression.
    #
    #   @param [Regex] regex
    #
    #   @return [nil] if no layout matches the regex
    #
    #   @return [Nanoc::LayoutView] if an layout was found
    def [](arg)
      res = @layouts[arg]
      res && view_class.new(res)
    end
  end
end
