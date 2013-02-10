# encoding: utf-8

module Nanoc

  # Acts as an array, but allows fetching items using identifiers, e.g. `@items['blah']`.
  class ItemArray

    extend Forwardable

    DELEGATED_METHODS = [
      :&,
      :*,
      :+,
      :-,
      :<=>,
      :==,
      :abbrev,
      :assoc,
      :collect,
      :combination,
      :compact,
      :compact!, # modifies, but has no relevant effect
      :count,
      :cycle,
      :dclone,
      :drop,
      :drop_while,
      :each,
      :each_index,
      :empty?,
      :eql?,
      :fetch,
      :find_index,
      :first,
      :flatten,
      :frozen?,
      :hash,
      :include?,
      :index,
      :insert,
      :join,
      :last,
      :length,
      :map,
      :pack,
      :permutation,
      :pretty_print,
      :pretty_print_cycle,
      :product,
      :rassoc,
      :reject,
      :repeated_combination,
      :repeated_permutation,
      :reverse,
      :reverse!, # modifies, but has no relevant effect
      :reverse_each,
      :rindex,
      :rotate,
      :rotate!, # modifies, but has no relevant effect
      :sample,
      :select,
      :shelljoin,
      :shuffle,
      :shuffle!, # modifies, but has no relevant effect
      :size,
      :sort,
      :sort!, # modifies, but has no relevant effect
      :sort_by,
      :sort_by!, # modifies, but has no relevant effect
      :take,
      :take_while,
      :to_a,
      :to_ary,
      :to_csv,
      :to_s,
      :transpose,
      :uniq,
      :values_at,
      :zip,
      :|
    ]
    DELEGATED_METHODS.each { |m| def_delegator :@items, m }

    def initialize(items)
      @items   = items.dup
      @mapping = {}
      items.each { |i| self._added(i) }
    end

    def update(item, old_identifier, new_identifier)
      @mapping.delete(old_identifier)
      @mapping[new_identifier] = item
    end

    # @!group Getting

    def [](*args)
      STDOUT.puts args.inspect if $LOUD
      if 1 == args.size && args.first.is_a?(String)
        @mapping[args.first]
      else
        @items[*args]
      end
    end
    alias_method :slice, :[]

    def at(arg)
      if arg.is_a?(String)
        @mapping[arg]
      else
        @items[arg]
      end
    end

    # @!group Modifying

    def <<(item)
      @items << item
      self._added(item)
    end

    def []=(index, new_item)
      if index.is_a?(String)
        raise ArgumentError, "Nanoc::ItemArray#[]= cannot be used with a string as index"
      end

      old_item = self[index]
      @items[index] = new_item

      self._removed(old_item)
      self._added(new_item)
    end

    def clear
      @items.each { |i| self._removed(i) }
      @items.clear
    end

    def collect!(&block)
      @items.each { |i| self._removed(i) }
      @items.collect!(&block)
      @items.each { |i| self._added(i) }
    end
    alias_method :map!, :collect!

    def concat(arr)
      @items.concat(arr)
      arr.each { |i| self._added(i) }
    end

    def delete(item)
      @items.delete(item)
      self._removed(item)
    end

    def delete_at(idx)
      # FIXME Should idx be allowed to be an identifier string?

      self._removed(@items[idx])
      @items.delete_at(idx)
    end

    def delete_if(&block)
      @items.each do |i|
        self._removed(i) if block[i]
      end

      @items.delete_if(&block)
    end

    def fill(*args, &block)
      # FIXME Make this more efficient

      @items.each { |i| self._removed(i) }
      @items.fill(*args, &block)
      @items.each { |i| self._added(i) }
    end

    def flatten!
      raise "The items array is already supposed to be flat!"
    end

    def keep_if(&block)
      @items.each do |i|
        self._removed(i) unless block[i]
      end

      @items.keep_if(&block)
    end

    def pop(n=1)
      @items.last(n).each { |i| self._removed(i) }
      @items.pop(n)
    end

    def push(*items)
      @items.push(*items)
      items.each { |i| self._added(i) }
    end

    def reject!(&block)
      @items.each do |i|
        self._removed(i) if block[i]
      end

      @items.reject!(&block)
    end

    def replace(arr)
      @items.each { |i| self._removed(i) }
      @items.replace(arr)
      @items.each { |i| self._added(i) }
    end
    alias_method :initialize_copy, :replace

    def select!(&block)
      @items.each do |i|
        self._removed(i) unless block[i]
      end

      @items.select!(&block)
    end

    def shift(n=1)
      @items.first(n).each { |i| self._removed(i) }
      @items.shift(n)
    end

    def slice!(*args)
      # FIXME Make this more efficient

      @items.each { |i| self._removed(i) }
      @items.slice!(*args)
      @items.each { |i| self._added(i) }
    end

    def uniq!
      raise "An items array cannot have duplicates!"
    end

    def unshift(*items)
      items.each { |i| self._added(i) }
      @items.unshift(*items)
    end

    protected

    def _added(item)
      item.add_observer(self)
      @mapping[item.identifier] = item
    end

    def _removed(item)
      item.delete_observer(self)
      @mapping.delete(item.identifier)
    end

  end

end
