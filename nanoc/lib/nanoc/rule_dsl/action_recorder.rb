# frozen_string_literal: true

module Nanoc
  module RuleDSL
    class ActionRecorder
      include Nanoc::Core::ContractsSupport

      contract Nanoc::Core::ItemRep => C::Any
      def initialize(rep)
        @action_sequence_builder = Nanoc::Core::ActionSequenceBuilder.new(rep)

        @any_layouts = false
        @last_snapshot = false
        @pre_snapshot = false
        @snapshots_for_which_to_skip_routing_rule = Set.new
      end

      def inspect
        "<#{self.class}>"
      end

      def filter(filter_name, filter_args = {})
        @action_sequence_builder.add_filter(filter_name, filter_args)
      end

      def layout(layout_identifier, extra_filter_args = {})
        unless layout_identifier.is_a?(String)
          raise ArgumentError.new('The layout passed to #layout must be a string')
        end

        unless any_layouts?
          @pre_snapshot = true
          @action_sequence_builder.add_snapshot(:pre, nil)
        end

        @action_sequence_builder.add_layout(layout_identifier, extra_filter_args)
        @any_layouts = true
      end

      MaybePathlike = C::Or[nil, Nanoc::Core::UNDEFINED, String, Nanoc::Core::Identifier]
      contract Symbol, C::KeywordArgs[path: C::Optional[MaybePathlike]] => nil
      def snapshot(snapshot_name, path: Nanoc::Core::UNDEFINED)
        unless Nanoc::Core::UNDEFINED.equal?(path)
          @snapshots_for_which_to_skip_routing_rule << snapshot_name
        end

        path =
          if Nanoc::Core::UNDEFINED.equal?(path) || path.nil?
            nil
          else
            path.to_s
          end

        @action_sequence_builder.add_snapshot(snapshot_name, path)
        case snapshot_name
        when :last
          @last_snapshot = true
        when :pre
          @pre_snapshot = true
        end
        nil
      end

      contract C::None => Nanoc::Core::ActionSequence
      def action_sequence
        @action_sequence_builder.action_sequence
      end

      contract C::None => C::Bool
      def any_layouts?
        @any_layouts
      end

      contract C::None => Set
      def snapshots_for_which_to_skip_routing_rule
        @snapshots_for_which_to_skip_routing_rule
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
