# encoding: utf-8

module Nanoc

  # Acts as an array, but allows fetching items using identifiers, e.g. `@items['/blah/']`.
  class ItemArray

    include Enumerable

    extend Forwardable

    DELEGATED_METHODS = Array.instance_methods + Enumerable.instance_methods - [ :[], :slice, :at, :initialize, :freeze ]
    def_delegators :@items, *DELEGATED_METHODS

    def initialize
      @items   = []
      @mapping = {}
    end

    def freeze
      super
      self.build_mapping
    end

    def [](*args)
      if 1 == args.size && args.first.is_a?(String)
        self.item_with_identifier(args.first)
      else
        @items[*args]
      end
    end
    alias_method :slice, :[]

    def at(arg)
      if arg.is_a?(String)
        self.item_with_identifier(arg)
      else
        @items[arg]
      end
    end

    protected

    def item_with_identifier(identifier)
      if self.frozen?
        @mapping[identifier]
      else
        @items.find { |i| i.identifier == identifier }
      end
    end

    def build_mapping
      @items.each do |item|
        @mapping[item.identifier] = item
      end
    end

  end

end
