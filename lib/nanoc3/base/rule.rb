# encoding: utf-8

module Nanoc3

  # Nanoc3::Rule contains the processing information for a item.
  class Rule

    # The regex that determines which items this rule can be applied to. This
    # rule can be applied to items with a identifier matching this regex.
    attr_reader :identifier_regex

    # The name of the representation that will be compiled using this rule.
    attr_reader :rep_name

    # Creates a new item compilation rule with the given identifier regex, compiler
    # and block. The block will be called during compilation with the item rep
    # as its argument.
    def initialize(identifier_regex, rep_name, block)
      @identifier_regex = identifier_regex
      @rep_name         = rep_name.to_sym

      @block = block
    end

    # Returns true if this rule can be applied to the given item rep.
    def applicable_to?(item)
      item.identifier =~ @identifier_regex
    end

    # Applies this rule to the given item rep.
    def apply_to(rep)
      @block.call(rep)
    end

  end

end
