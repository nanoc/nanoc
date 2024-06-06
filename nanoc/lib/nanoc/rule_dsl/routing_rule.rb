# frozen_string_literal: true

module Nanoc::RuleDSL
  class RoutingRule < Rule
    include Nanoc::Core::ContractsSupport

    contract C::None => C::Maybe[Symbol]
    attr_reader :snapshot_name

    contract Nanoc::Core::Pattern, Symbol, Proc, C::KeywordArgs[snapshot_name: C::Optional[Symbol]] => C::Any
    def initialize(pattern, rep_name, block, snapshot_name: nil)
      super(pattern, rep_name, block)

      @snapshot_name = snapshot_name
    end

    contract Nanoc::Core::ItemRep, C::KeywordArgs[
      site: Nanoc::Core::Site,
      view_context: Nanoc::Core::ViewContextForPreCompilation,
    ] => C::Any
    def apply_to(rep, site:, view_context:)
      context = Nanoc::RuleDSL::RoutingRuleContext.new(
        rep:, site:, view_context:,
      )

      context.instance_exec(matches(rep.item.identifier), &@block)
    end
  end
end
