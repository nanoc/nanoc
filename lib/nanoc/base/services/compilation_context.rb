module Nanoc::Int
  class CompilationContext
    attr_reader :site
    attr_reader :compiled_content_cache
    attr_reader :snapshot_repo

    def initialize(action_provider:, reps:, site:, compiled_content_cache:, snapshot_repo:)
      @action_provider = action_provider
      @reps = reps
      @site = site
      @compiled_content_cache = compiled_content_cache
      @snapshot_repo = snapshot_repo
    end

    def filter_name_and_args_for_layout(layout)
      seq = @action_provider.action_sequence_for(layout)
      if seq.nil? || seq.size != 1 || !seq[0].is_a?(Nanoc::Int::ProcessingActions::Filter)
        raise Nanoc::Int::Errors::UndefinedFilterForLayout.new(layout)
      end
      [seq[0].filter_name, seq[0].params]
    end

    def create_view_context(dependency_tracker)
      Nanoc::ViewContext.new(
        reps: @reps,
        items: @site.items,
        dependency_tracker: dependency_tracker,
        compilation_context: self,
        snapshot_repo: @snapshot_repo,
      )
    end

    def assigns_for(rep, dependency_tracker)
      last_content = @snapshot_repo.get(rep, :last)
      content_or_filename_assigns =
        if last_content.binary?
          { filename: last_content.filename }
        else
          { content: last_content.string }
        end

      view_context = create_view_context(dependency_tracker)

      content_or_filename_assigns.merge(
        item: Nanoc::ItemWithRepsView.new(rep.item, view_context),
        rep: Nanoc::ItemRepView.new(rep, view_context),
        item_rep: Nanoc::ItemRepView.new(rep, view_context),
        items: Nanoc::ItemCollectionWithRepsView.new(@site.items, view_context),
        layouts: Nanoc::LayoutCollectionView.new(@site.layouts, view_context),
        config: Nanoc::ConfigView.new(@site.config, view_context),
      )
    end
  end
end
