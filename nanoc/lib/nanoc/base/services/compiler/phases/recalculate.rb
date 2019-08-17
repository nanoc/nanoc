# frozen_string_literal: true

module Nanoc
  module Int
    class Compiler
      module Phases
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
            dependency_tracker = Nanoc::Core::DependencyTracker.new(@dependency_store)
            dependency_tracker.enter(rep.item)

            executor = Nanoc::Int::Executor.new(rep, @compilation_context, dependency_tracker)

            @compilation_context.compiled_content_store.set_current(rep, rep.item.content)

            actions = @action_sequences[rep]
            actions.each do |action|
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
                raise Nanoc::Int::Errors::InternalInconsistency, "unknown action #{action.inspect}"
              end
            end
          ensure
            dependency_tracker.exit
          end
        end
      end
    end
  end
end
