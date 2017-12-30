# frozen_string_literal: true

module Nanoc::RuleDSL
  # Contains the processing information for a item.
  #
  # @api private
  class RoutingRule
    include Nanoc::Int::ContractsSupport

    # @return [Symbol] The name of the representation that will be compiled
    #   using this rule
    attr_reader :rep_name

    # @return [Symbol] The name of the snapshot this rule will apply to.
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
    # @param [Symbol, nil] snapshot_name The name of the snapshot this rule will
    #   apply to.
    def initialize(pattern, rep_name, block, snapshot_name: nil)
      @pattern = pattern
      @rep_name = rep_name.to_sym
      @snapshot_name = snapshot_name
      @block = block
    end

    # @param [Nanoc::Int::Item] item The item to check
    #
    # @return [Boolean] true if this rule can be applied to the given item
    #   rep, false otherwise
    def applicable_to?(item)
      @pattern.match?(item.identifier)
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[
      site: Nanoc::Int::Site,
      view_context: Nanoc::ViewContextForPreCompilation,
    ] => C::Any
    def apply_to(rep, site:, view_context:)
      context = Nanoc::Int::Context.new(
        item: Nanoc::BasicItemView.new(rep.item, view_context),
        rep: Nanoc::BasicItemRepView.new(rep, view_context),
        item_rep: Nanoc::BasicItemRepView.new(rep, view_context),
        items: Nanoc::ItemCollectionWithoutRepsView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
      )

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
