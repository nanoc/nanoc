module Nanoc

  # Nanoc::ItemRule contains the processing information for a item.
  class ItemRule

    # The regex that determines which items this rule can be applied to. This
    # rule can be applied to items with a path matching this regex.
    attr_reader :path_regex

    # The name of the representation that will be compiled using this rule.
    attr_reader :rep_name

    # Creates a new item compilation rule with the given path regex, compiler
    # and block. The block will be called during compilation with the item rep
    # as its argument.
    def initialize(path_regex, rep_name, compiler, block)
      @path_regex = path_regex
      @rep_name   = rep_name.to_sym

      @compiler   = compiler

      @block      = block
    end

    # Returns true if this rule can be applied to the given item rep.
    def applicable_to?(item)
      item.path =~ @path_regex
    end

    # Applies this rule to the given item rep.
    def apply_to(rep)
      @block.call(rep)
    end

  end

end
