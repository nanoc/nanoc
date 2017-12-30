# frozen_string_literal: true

module Nanoc::RuleDSL
  # Provides a context in which compilation and routing rules can be executed.
  # It provides access to the item representation that is being compiled or
  # routed.
  #
  # @api private
  class RuleContext < Nanoc::Int::Context
    # @param [Nanoc::Int::ItemRep] rep
    # @param [Nanoc::Int::Site] site
    # @param [Nanoc::ViewContextForCompilation] view_context
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
