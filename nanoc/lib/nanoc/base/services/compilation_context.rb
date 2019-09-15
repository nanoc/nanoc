# frozen_string_literal: true

module Nanoc
  module Int
    class CompilationContext
      class FilterNameAndArgs
        include Nanoc::Core::ContractsSupport

        attr_reader :name
        attr_reader :args

        contract C::KeywordArgs[name: C::Maybe[Symbol], args: Hash] => C::Any
        def initialize(name:, args:)
          @name = name
          @args = args
        end
      end

      class UndefinedFilterForLayoutError < ::Nanoc::Core::Error
        def initialize(layout)
          super("There is no filter defined for the layout #{layout.identifier}")
        end
      end

      include Nanoc::Core::ContractsSupport

      attr_reader :site
      attr_reader :compiled_content_cache
      attr_reader :compiled_content_store

      C_COMPILED_CONTENT_CACHE =
        C::Or[
          Nanoc::Core::CompiledContentCache,
          Nanoc::Core::TextualCompiledContentCache,
          Nanoc::Core::BinaryCompiledContentCache,
        ]

      contract C::KeywordArgs[
        action_provider: Nanoc::Core::ActionProvider,
        reps: Nanoc::Core::ItemRepRepo,
        site: Nanoc::Core::Site,
        compiled_content_cache: C_COMPILED_CONTENT_CACHE,
        compiled_content_store: Nanoc::Core::CompiledContentStore,
      ] => C::Any
      def initialize(action_provider:, reps:, site:, compiled_content_cache:, compiled_content_store:)
        @action_provider = action_provider
        @reps = reps
        @site = site
        @compiled_content_cache = compiled_content_cache
        @compiled_content_store = compiled_content_store
      end

      contract Nanoc::Core::Layout => FilterNameAndArgs
      def filter_name_and_args_for_layout(layout)
        seq = @action_provider.action_sequence_for(layout)
        if seq.nil? || seq.size != 1 || !seq[0].is_a?(Nanoc::Core::ProcessingActions::Filter)
          raise UndefinedFilterForLayoutError.new(layout)
        end

        FilterNameAndArgs.new(name: seq[0].filter_name, args: seq[0].params)
      end

      contract Nanoc::Core::DependencyTracker => C::Named['Nanoc::ViewContextForCompilation']
      def create_view_context(dependency_tracker)
        Nanoc::ViewContextForCompilation.new(
          reps: @reps,
          items: @site.items,
          dependency_tracker: dependency_tracker,
          compilation_context: self,
          compiled_content_store: @compiled_content_store,
        )
      end
    end
  end
end
