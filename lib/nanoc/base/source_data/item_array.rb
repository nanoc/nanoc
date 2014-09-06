# encoding: utf-8

module Nanoc

  # Acts as an array, but allows fetching items using identifiers, e.g. `@items['/blah/']`.
  class ItemArray

    include Enumerable

    extend Forwardable

    EXCLUDED_METHODS  = [
      :[], :at, :slice, :class, :singleton_class, :clone, :dup, :initialize_dup, :initialize_clone,
      :freeze, :methods, :singleton_methods, :protected_methods, :private_methods, :public_methods,
      :instance_variables, :instance_variable_get, :instance_variable_set, :instance_variable_defined?,
      :instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, :respond_to?, :respond_to_missing?,
      :extend, :display, :method, :public_method, :define_singleton_method, :object_id, :equal?,
      :instance_eval, :instance_exec, :__send__, :__id__
    ]

    DELEGATED_METHODS = (Array.instance_methods + Enumerable.instance_methods).map { |m| m.to_sym } - EXCLUDED_METHODS
    def_delegators :@items, *DELEGATED_METHODS

    def initialize
      @items = []
    end

    def freeze
      @items.freeze
      build_mapping
      super
    end

    def [](*args)
      if 1 == args.size && args.first.is_a?(String)
        item_with_identifier(args.first)
      elsif 1 == args.size && args.first.is_a?(Regexp)
        @items.select { |i| i.identifier =~ args.first }
      else
        @items[*args]
      end
    end
    alias_method :slice, :[]

    def at(arg)
      if arg.is_a?(String)
        item_with_identifier(arg)
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
      @mapping = {}
      @items.each do |item|
        @mapping[item.identifier] = item
      end
      @mapping.freeze
    end

  end

end
