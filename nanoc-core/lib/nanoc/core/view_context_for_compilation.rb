# frozen_string_literal: true

module Nanoc
  module Core
    class ViewContextForCompilation
      include Nanoc::Core::ContractsSupport

      attr_reader :reps
      attr_reader :items
      attr_reader :dependency_tracker
      attr_reader :compilation_context
      attr_reader :compiled_content_store

      contract C::KeywordArgs[
        reps: Nanoc::Core::ItemRepRepo,
        items: Nanoc::Core::IdentifiableCollection,
        dependency_tracker: Nanoc::Core::DependencyTracker,
        compilation_context: Nanoc::Core::CompilationContext,
        compiled_content_store: Nanoc::Core::CompiledContentStore,
      ] => C::Any
      def initialize(reps:, items:, dependency_tracker:, compilation_context:, compiled_content_store:)
        @reps = reps
        @items = items
        @dependency_tracker = dependency_tracker
        @compilation_context = compilation_context
        @compiled_content_store = compiled_content_store
      end

      contract Nanoc::Core::ItemRep, C::KeywordArgs[site: Nanoc::Core::Site] => Hash
      def assigns_for(rep, site:)
        last_content = @compiled_content_store.get_current(rep)
        content_or_filename_assigns =
          if last_content.binary?
            { filename: last_content.filename }
          else
            { content: last_content.string }
          end

        content_or_filename_assigns.merge(
          item: Nanoc::Core::CompilationItemView.new(rep.item, self),
          rep: Nanoc::Core::CompilationItemRepView.new(rep, self),
          item_rep: Nanoc::Core::CompilationItemRepView.new(rep, self),
          items: Nanoc::Core::ItemCollectionWithRepsView.new(site.items, self),
          layouts: Nanoc::Core::LayoutCollectionView.new(site.layouts, self),
          config: Nanoc::Core::ConfigView.new(site.config, self),
        )
      end
    end
  end
end
