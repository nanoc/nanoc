# frozen_string_literal: true

module Nanoc::RuleDSL
  class RuleContext < Nanoc::Core::Context
    include Nanoc::Core::ContractsSupport

    contract C::KeywordArgs[
      rep: Nanoc::Core::ItemRep,
      site: Nanoc::Core::Site,
      view_context: Nanoc::Core::ViewContextForPreCompilation,
    ] => C::Any
    def initialize(rep:, site:, view_context:)
      super({
        item: Nanoc::Core::BasicItemView.new(rep.item, view_context),
        rep: Nanoc::Core::BasicItemRepView.new(rep, view_context),
        item_rep: Nanoc::Core::BasicItemRepView.new(rep, view_context),
        items: Nanoc::Core::ItemCollectionWithoutRepsView.new(site.items, view_context),
        layouts: Nanoc::Core::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::Core::ConfigView.new(site.config, view_context),
      })
    end
  end
end
