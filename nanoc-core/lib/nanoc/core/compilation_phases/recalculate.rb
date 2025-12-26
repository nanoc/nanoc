# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      # Provides functionality for (re)calculating the content of an item rep, without caching or
      # outdatedness checking.
      class Recalculate < Abstract
        include Nanoc::Core::ContractsSupport

        def initialize(action_sequences:, dependency_store:, compilation_context:)
          super(wrapped: nil)

          @action_sequences = action_sequences
          @dependency_store = dependency_store
          @compilation_context = compilation_context
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          dependency_tracker = Nanoc::Core::DependencyTracker.new(@dependency_store, root: rep.item)

          executor = Nanoc::Core::Executor.new(rep, @compilation_context, dependency_tracker)

          # Set initial content, if not already present
          compiled_content_repo = @compilation_context.compiled_content_repo
          unless compiled_content_repo.get_current(rep)
            compiled_content_repo.set_current(rep, rep.item.content)
          end

          actions = pending_action_sequence_for(rep:)
          until actions.empty?
            action = actions.first

            case action
            when Nanoc::Core::ProcessingActions::Filter
              executor.filter(action.filter_name, action.params)
            when Nanoc::Core::ProcessingActions::Layout
              executor.layout(action.layout_identifier, action.params)
            when Nanoc::Core::ProcessingActions::Snapshot
              action.snapshot_names.each do |snapshot_name|
                executor.snapshot(snapshot_name)
              end
            else
              raise Nanoc::Core::Errors::InternalInconsistency, "unknown action #{action.inspect}"
            end

            actions.shift
          end
        end

        def pending_action_sequence_for(rep:)
          @_pending_action_sequences ||= {}
          @_pending_action_sequences[rep] ||= @action_sequences[rep].to_a
        end
      end
    end
  end
end
