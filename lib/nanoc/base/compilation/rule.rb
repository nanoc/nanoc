# encoding: utf-8

module Nanoc

  # Contains the processing information for a item.
  class Rule

    # @return [Pattern] pattern A pattern that will be used to determine
    #   whether this rule is applicable to certain items.
    attr_reader :pattern

    # @return [Symbol] The name of the representation that will be compiled
    #   using this rule
    attr_reader :rep_name

    # @return [Symbol] The name of the snapshot this rule will apply to.
    #   Ignored for compilation rules, but used for routing rules.
    attr_reader :snapshot_name

    # Creates a new item compilation rule with the given pattern, compiler and
    # block. The block will be called during compilation with the item rep as
    # its argument.
    #
    # @param [String, Regexp] pattern Either a string containing a glob or a
    #   regular expression that will be used to determine whether this rule
    #   is applicable to certain items.
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
    def initialize(pattern, rep_name, block, params={})
      @pattern       = pattern
      @rep_name      = rep_name.to_sym
      @snapshot_name = params[:snapshot_name]

      @block = block
    end

    # @param [Nanoc::Item] item The item to check
    #
    # @return [Boolean] true if this rule can be applied to the given item
    #   rep, false otherwise
    def applicable_to?(item)
      self.pattern.match?(item.identifier)
    end

    # Applies this rule to the given item rep.
    #
    # @param [Nanoc::ItemRep] rep The item representation where this rule
    #   should be applied to
    #
    # @option params [Nanoc::Compiler] :compiler The compiler
    #
    # @raise [ArgumentError] if no compiler is passed
    #
    # @return [void]
    def apply_to(rep, params={})
      compiler = params[:compiler] or raise ArgumentError, "Required :compiler option is missing"
      rep = Nanoc::ItemRepRulesProxy.new(rep, compiler) unless rep.is_proxy?
      Nanoc::RuleContext.new(:rep => rep, :site => compiler.site).instance_eval &@block
    end

  end

end
