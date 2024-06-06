# frozen_string_literal: true

module Nanoc::RuleDSL
  class CompilationRule < Rule
    include Nanoc::Core::ContractsSupport

    contract Nanoc::Core::ItemRep, C::KeywordArgs[
      site: Nanoc::Core::Site,
      recorder: Nanoc::RuleDSL::ActionRecorder,
      view_context: Nanoc::Core::ViewContextForPreCompilation,
    ] => C::Any
    def apply_to(rep, site:, recorder:, view_context:)
      context = Nanoc::RuleDSL::CompilationRuleContext.new(
        rep:,
        recorder:,
        site:,
        view_context:,
      )

      context.instance_exec(matches(rep.item.identifier), &@block)
    end
  end
end
