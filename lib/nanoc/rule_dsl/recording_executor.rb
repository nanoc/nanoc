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
          @rule_memory.add_snapshot(:pre, true, nil)
        end

        @rule_memory.add_layout(layout_identifier, extra_filter_args)
      end

      Pathlike = C::Maybe[C::Or[String, Nanoc::Identifier]]
      contract Symbol, C::KeywordArgs[path: C::Optional[Pathlike], final: C::Optional[C::Bool]] => nil
      def snapshot(snapshot_name, final: true, path: nil)
        @rule_memory.add_snapshot(snapshot_name, final, path && final ? path.to_s : nil)
        nil
      end
    end
  end
end
