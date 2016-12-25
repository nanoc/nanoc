module Nanoc
  module RuleDSL
    class RecordingExecutor
      include Nanoc::Int::ContractsSupport

      def initialize(rule_memory)
        @rule_memory = rule_memory
      end

      def filter(filter_name, filter_args = {})
        @rule_memory.add_filter(filter_name, filter_args)
      end

      def layout(layout_identifier, extra_filter_args = {})
        unless layout_identifier.is_a?(String)
          raise ArgumentError.new('The layout passed to #layout must be a string')
        end

        unless @rule_memory.any_layouts?
          @rule_memory.add_snapshot(:pre, nil)
        end

        @rule_memory.add_layout(layout_identifier, extra_filter_args)
      end

      Pathlike = C::Maybe[C::Or[String, Nanoc::Identifier]]
      contract Symbol, C::KeywordArgs[path: C::Optional[Pathlike]] => nil
      def snapshot(snapshot_name, path: nil)
        @rule_memory.add_snapshot(snapshot_name, path && path.to_s)
        nil
      end
    end
  end
end
