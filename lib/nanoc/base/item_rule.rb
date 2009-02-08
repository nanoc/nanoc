module Nanoc

  # Nanoc::ItemRule contains the processing information for a item.
  class ItemRule

    # The regex that determines which items this rule can be applied to. This
    # rule can be applied to items with a path matching this regex.
    attr_reader :path_regex

    # Creates a new item compilation rule with the given path regex, compiler
    # and block. The block will be called during compilation with the item rep
    # as its argument.
    def initialize(path_regex, compiler, block)
      @path_regex = path_regex
      @compiler   = compiler
      @block      = block
    end

    # Returns true if this rule can be applied to the given item rep.
    def applicable_to?(rep)
      rep.item.path =~ @path_regex
    end

    # Applies this rule to the given item rep.
    def apply_to(rep)
      @block.call(rep)
    end

  end

end
