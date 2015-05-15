# encoding: utf-8

module Nanoc::Int
  # Acts as an array, but allows fetching items using identifiers, e.g. `@items['/blah/']`.
  #
  # @api private
  class ItemArray
    include Enumerable

    extend Forwardable

    def_delegator :@items, :each
    def_delegator :@items, :size
    def_delegator :@items, :<<
    def_delegator :@items, :concat

    def initialize(config)
      @config = config

      @items = []
    end

    def freeze
      @items.freeze
      build_mapping
      super
    end

    def [](arg)
      case arg
      when String
        item_with_identifier(arg) || item_matching_glob(arg)
      when Regexp
        @items.find { |i| i.identifier.to_s =~ arg }
      else
        raise ArgumentError, "don’t know how to fetch items by #{arg.inspect}"
      end
    end

    def to_a
      @items
    end

    protected

    def item_with_identifier(identifier)
      if self.frozen?
        @mapping[identifier.to_s]
      else
        @items.find { |i| i.identifier == identifier }
      end
    end

    def item_matching_glob(glob)
      if use_globs?
        pat = Nanoc::Int::Pattern.from(glob)
        @items.find { |i| pat.match?(i.identifier) }
      else
        nil
      end
    end

    def build_mapping
      @mapping = {}
      @items.each do |item|
        @mapping[item.identifier.to_s] = item
      end
      @mapping.freeze
    end

    def use_globs?
      @config[:pattern_syntax] == 'glob'
    end
  end
end
