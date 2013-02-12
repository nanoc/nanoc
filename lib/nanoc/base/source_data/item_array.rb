# encoding: utf-8

module Nanoc

  # Acts as an array, but allows fetching items using identifiers, e.g. `@items['/blah/']`.
  class ItemArray

    include Enumerable

    extend Forwardable

    DELEGATED_METHODS = [
      :&,
      :*,
      :+,
      :-,
      :<<,
      :<=>,
      :==,
      :[]=,
      :abbrev,
      :assoc,
      :clear,
      :collect!,
      :collect,
      :combination,
      :compact!,
      :compact,
      :concat,
      :count,
      :cycle,
      :dclone,
      :delete,
      :delete_at,
      :delete_if,
      :drop,
      :drop_while,
      :each,
      :each_index,
      :empty?,
      :eql?,
      :fetch,
      :fill,
      :find_index,
      :first,
      :flatten!,
      :flatten,
      :frozen?,
      :hash,
      :include?,
      :index,
      :initialize_copy,
      :insert,
      :join,
      :keep_if,
      :last,
      :length,
      :map!,
      :map,
      :pack,
      :permutation,
      :pop,
      :pretty_print,
      :pretty_print_cycle,
      :product,
      :push,
      :rassoc,
      :reject!,
      :reject,
      :repeated_combination,
      :repeated_permutation,
      :replace,
      :reverse!,
      :reverse,
      :reverse_each,
      :rindex,
      :rotate!,
      :rotate,
      :sample,
      :select!,
      :select,
      :shelljoin,
      :shift,
      :shuffle!,
      :shuffle,
      :size,
      :slice!,
      :sort!,
      :sort,
      :sort_by!,
      :sort_by,
      :take,
      :take_while,
      :to_a,
      :to_ary,
      :to_csv,
      :to_s,
      :transpose,
      :uniq!,
      :uniq,
      :unshift,
      :values_at,
      :zip,
      :|,
    ]
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
