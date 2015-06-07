module Nanoc::Int
  # Contains the processing information for a item.
  #
  # @api private
  class Rule
    # @return [Symbol] The name of the representation that will be compiled
    #   using this rule
    attr_reader :rep_name

    # @return [Symbol] The name of the snapshot this rule will apply to.
    #   Ignored for compilation rules, but used for routing rules.
    #
    # @since 3.2.0
    attr_reader :snapshot_name

    # Creates a new item compilation rule with the given identifier regex,
    # compiler and block. The block will be called during compilation with the
    # item rep as its argument.
    #
    # @param [Nanoc::Int::Pattern] pattern
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
    def initialize(pattern, rep_name, block, params = {})
      # TODO: remove me
      unless pattern.is_a?(Nanoc::Int::StringPattern) || pattern.is_a?(Nanoc::Int::RegexpPattern)
        raise 'Can only create rules with patterns'
      end

      @pattern          = pattern
      @rep_name         = rep_name.to_sym
      @snapshot_name    = params[:snapshot_name]

      @block = block
    end

    # @param [Nanoc::Int::Item] item The item to check
    #
    # @return [Boolean] true if this rule can be applied to the given item
    #   rep, false otherwise
    def applicable_to?(item)
      @pattern.match?(item.identifier)
    end

    # Applies this rule to the given item rep.
    #
    # @param [Nanoc::Int::ItemRep] rep The item representation where this rule
    #   should be applied to
    #
    # @option params [Nanoc::Int::Compiler] :compiler The compiler
    #
    # @raise [ArgumentError] if no compiler is passed
    #
    # @return [void]
    def apply_to(rep, params = {})
      compiler = params.fetch(:compiler)
      executor = params.fetch(:executor)

      context = Nanoc::Int::RuleContext.new(rep: rep, executor: executor, compiler: compiler)
      context.instance_exec(matches(rep.item.identifier), &@block)
    end

    protected

    # Matches the rule regexp against items identifier and gives back group
    # captures if any
    #
    # @param [String] identifier Identifier to capture groups for
    #
    # @return [nil, Array] Captured groups, if any
    def matches(identifier)
      @pattern.captures(identifier)
    end
  end
end
