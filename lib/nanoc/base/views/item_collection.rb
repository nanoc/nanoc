# encoding: utf-8

module Nanoc
  class ItemCollectionView
    include Enumerable

    # @api private
    def initialize(items)
      @items = items
    end

    # @api private
    def unwrap
      @items
    end

    # @api private
    def view_class
      Nanoc::ItemView
    end

    # Calls the given block once for each item, passing that item as a parameter.
    #
    # @yieldparam [Nanoc::ItemView] item
    #
    # @yieldreturn [void]
    #
    # @return [self]
    def each
      @items.each { |i| yield view_class.new(i) }
      self
    end

    # @return [Integer]
    def size
      @items.size
    end

    # Finds the item whose identifier matches the given string.
    #
    # @param [String] arg
    #
    # @return [nil] if no item matches the string
    #
    # @return [Nanoc::ItemView] if an item was found
    def at(arg)
      item = @items.at(arg)
      item && view_class.new(item)
    end

    # Finds all items whose identifier matches the given argument.
    #
    # @param [String, Regex] arg
    #
    # @return [Enumerable<Nanoc::ItemView>]
    def find_all(arg)
      pat = Nanoc::Int::Pattern.from(arg)
      select { |i| pat.match?(i.identifier) }
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
      res = @items[arg]
      case res
      when nil
        nil
      else
        view_class.new(res)
      end
    end
  end
end
