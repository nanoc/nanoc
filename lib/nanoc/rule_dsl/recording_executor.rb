module Nanoc
  module RuleDSL
    class RecordingExecutor
      include Nanoc::Int::ContractsSupport

      attr_reader :action_sequence

      contract Nanoc::Int::ItemRep => C::Any
      def initialize(rep)
        @action_sequence = Nanoc::Int::ActionSequence.new(rep)

        @any_layouts = false
        @last_snapshot = false
        @pre_snapshot = false
      end

      def filter(filter_name, filter_args = {})
        @action_sequence.add_filter(filter_name, filter_args)
      end

      def layout(layout_identifier, extra_filter_args = {})
        unless layout_identifier.is_a?(String)
          raise ArgumentError.new('The layout passed to #layout must be a string')
        end

        unless any_layouts?
          @pre_snapshot = true
          @action_sequence.add_snapshot(:pre, nil)
        end

        @action_sequence.add_layout(layout_identifier, extra_filter_args)
        @any_layouts = true
      end

      Pathlike = C::Maybe[C::Or[String, Nanoc::Identifier]]
      contract Symbol, C::KeywordArgs[path: C::Optional[Pathlike]] => nil
      def snapshot(snapshot_name, path: nil)
        @action_sequence.add_snapshot(snapshot_name, path && path.to_s)
        case snapshot_name
        when :last
          @last_snapshot = true
        when :pre
          @pre_snapshot = true
        end
        nil
      end

      contract C::None => C::Bool
      def any_layouts?
        @any_layouts
      end

      contract C::None => C::Bool
      def last_snapshot?
        @last_snapshot
      end

      contract C::None => C::Bool
      def pre_snapshot?
        @pre_snapshot
      end
    end
  end
end
