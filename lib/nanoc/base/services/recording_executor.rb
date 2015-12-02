module Nanoc
  module Int
    class RecordingExecutor
      attr_reader :rule_memory

      def initialize(item_rep)
        @item_rep = item_rep
        @rule_memory = Nanoc::Int::RuleMemory.new(item_rep)
      end

      def filter(_rep, filter_name, filter_args = {})
        @rule_memory.add_filter(filter_name, filter_args)
      end

      def layout(_rep, layout_identifier, extra_filter_args = {})
        @rule_memory.add_layout(layout_identifier, extra_filter_args)
      end

      def snapshot(_rep, snapshot_name, final: true)
        @rule_memory.add_snapshot(snapshot_name, final)
      end

      def record_write(_rep, path)
        @rule_memory.add_write(path)
      end
    end
  end
end
