module Nanoc::Int
  # @api private
  class Postprocessor
    def initialize(site:, rules_collection:)
      @site = site
      @rules_collection = rules_collection
    end

    def run
      ctx = new_postprocessor_context

      @rules_collection.postprocessors.each_value do |postprocessor|
        ctx.instance_eval(&postprocessor)
      end

      # Nanoc::Int::SiteLoader.new.setup_child_parent_links(@site.items)
    end

    # @api private
    def new_postprocessor_context
      Nanoc::Int::Context.new({
        config: Nanoc::ConfigView.new(@site.config, nil),
        items: Nanoc::ItemCollectionView.new(@site.items, nil),
        layouts: Nanoc::LayoutCollectionView.new(@site.layouts, nil),
      })
    end
  end
end
