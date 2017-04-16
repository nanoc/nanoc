module Nanoc
  module RuleDSL
    class RecordingExecutor
      include Nanoc::Int::ContractsSupport

      attr_reader :action_sequence

      contract Nanoc::Int::ItemRep => C::Any
      def initialize(rep)
        @action_sequence = Nanoc::Int::ActionSequence.new(rep)
      end

      def filter(filter_name, filter_args = {})
        @action_sequence.add_filter(filter_name, filter_args)
      end

      def layout(layout_identifier, extra_filter_args = {})
        unless layout_identifier.is_a?(String)
          raise ArgumentError.new('The layout passed to #layout must be a string')
        end

        unless @action_sequence.any_layouts?
          @action_sequence.add_snapshot(:pre, nil)
        end

        @action_sequence.add_layout(layout_identifier, extra_filter_args)
      end

      Pathlike = C::Maybe[C::Or[String, Nanoc::Identifier]]
      contract Symbol, C::KeywordArgs[path: C::Optional[Pathlike]] => nil
      def snapshot(snapshot_name, path: nil)
        @action_sequence.add_snapshot(snapshot_name, path && path.to_s)
        nil
      end

      contract C::None => C::Bool
      def any_layouts?
        @action_sequence.any_layouts?
      end

      contract C::None => C::Bool
      def last_snapshot?
        @action_sequence.snapshot_actions.any? { |sa| sa.snapshot_names.include?(:last) }
      end

      contract C::None => C::Bool
      def pre_snapshot?
        @action_sequence.snapshot_actions.any? { |sa| sa.snapshot_names.include?(:pre) }
      end
    end
  end
end
