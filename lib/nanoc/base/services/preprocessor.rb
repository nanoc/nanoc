module Nanoc::Int
  # @api private
  class Preprocessor
    def initialize(site:, rules_collection:)
      @site = site
      @rules_collection = rules_collection
    end

    def run
      ctx = new_preprocessor_context

      @rules_collection.preprocessors.each_value do |preprocessor|
        ctx.instance_eval(&preprocessor)
      end

      Nanoc::Int::SiteLoader.new.setup_child_parent_links(@site.items)
    end

    # @api private
    def new_preprocessor_context
      Nanoc::Int::Context.new({
        config: Nanoc::MutableConfigView.new(@site.config),
        items: Nanoc::MutableItemCollectionView.new(@site.items, nil),
        layouts: Nanoc::MutableLayoutCollectionView.new(@site.layouts, nil),
      })
    end
  end
end
