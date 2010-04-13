# encoding: utf-8

module Nanoc3

  # Contains the processing information for a item.
  class Rule

    # @return [Regexp] The regex that determines which items this rule can be
    #   applied to. This rule can be applied to items with a identifier
    #   matching this regex.
    attr_reader :identifier_regex

    # @return [Symbol] The name of the representation that will be compiled
    #   using this rule
    attr_reader :rep_name

    # @return [Symbol] The name of the snapshot this rule will apply to.
    #   Ignored for compilation rules, but used for routing rules.
    attr_reader :snapshot_name

    # Creates a new item compilation rule with the given identifier regex,
    # compiler and block. The block will be called during compilation with the
    # item rep as its argument.
    #
    # @param [Regexp] identifier_regex A regular expression that will be used
    #   to determine whether this rule is applicable to certain items.
    #
    # @param [String, Symbol] rep_name The name of the item representation
    #   where this rule can be applied to
    #
    # @param [Proc] block A block that will be called when matching items are
    #   compiled
    #
    # @option params [Symbol, nil] :snapshot (nil) The name of the snapshot
    #   this rule will apply to. Ignored for compilation rules, but used for
    #   routing rules.
    def initialize(identifier_regex, rep_name, block, params={})
      @identifier_regex = identifier_regex
      @rep_name         = rep_name.to_sym
      @snapshot_name    = params[:snapshot_name]

      @block = block
    end

    # @param [Nanoc3::Item] item The item to check
    #
    # @return [Boolean] true if this rule can be applied to the given item
    #   rep, false otherwise
    def applicable_to?(item)
      item.identifier =~ @identifier_regex
    end

    # Applies this rule to the given item rep.
    #
    # @param [Nanoc3::ItemRep] rep The item representation where this rule
    #   should be applied to
    #
    # @return [void]
    def apply_to(rep)
      Nanoc3::RuleContext.new(rep).instance_eval &@block
    end

  end

end
