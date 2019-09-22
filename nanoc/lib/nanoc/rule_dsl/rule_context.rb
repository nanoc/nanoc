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
        item: Nanoc::Base::BasicItemView.new(rep.item, view_context),
        rep: Nanoc::Base::BasicItemRepView.new(rep, view_context),
        item_rep: Nanoc::Base::BasicItemRepView.new(rep, view_context),
        items: Nanoc::Base::ItemCollectionWithoutRepsView.new(site.items, view_context),
        layouts: Nanoc::Base::LayoutCollectionView.new(site.layouts, view_context),
        config: Nanoc::Base::ConfigView.new(site.config, view_context),
      })
    end
  end
end
