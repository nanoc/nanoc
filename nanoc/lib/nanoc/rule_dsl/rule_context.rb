# frozen_string_literal: true

module Nanoc::RuleDSL
  class RuleContext < Nanoc::Int::Context
    include Nanoc::Int::ContractsSupport

    contract C::KeywordArgs[
      rep: Nanoc::Int::ItemRep,
      site: Nanoc::Int::Site,
      view_context: Nanoc::ViewContextForPreCompilation,
    ] => C::Any
    def initialize(rep:, site:, view_context:)
      super({
        item: Nanoc::BasicItemView.new(rep.item, view_context),
        rep: Nanoc::BasicItemRepView.new(rep, view_context),
        item_rep: Nanoc::BasicItemRepView.new(rep, view_context),
        items: Nanoc::ItemCollectionWithoutRepsView.new(site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::ConfigView.new(site.config, view_context),
      })
    end
  end
end
