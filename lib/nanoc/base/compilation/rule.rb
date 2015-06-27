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

    attr_reader :pattern

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
    # @param [Symbol, nil] :snapshot The name of the snapshot this rule will
    #   apply to. Ignored for compilation rules, but used for routing rules.
    def initialize(pattern, rep_name, block, snapshot_name: nil)
      # TODO: remove me
      unless pattern.is_a?(Nanoc::Int::StringPattern) || pattern.is_a?(Nanoc::Int::RegexpPattern)
        raise 'Can only create rules with patterns'
      end

      @pattern          = pattern
      @rep_name         = rep_name.to_sym
      @snapshot_name    = snapshot_name

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
    # @param [Nanoc::Int::ItemRep] rep
    #
    # @param [Nanoc::Int::Site] site
    #
    # @param [Nanoc::Int::Executor, Nanoc::Int::RecordingExecutor] executor
    #
    # @return [void]
    def apply_to(rep, site:, executor:, reps: nil)
      # TODO: make reps mandatory
      context = Nanoc::Int::RuleContext.new(
        reps: reps, rep: rep, executor: executor, site: site)
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
