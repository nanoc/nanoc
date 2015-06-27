module Nanoc
  module Int
    class RecordingExecutor
      attr_reader :rule_memory

      def initialize
        @rule_memory = []
      end

      def filter(_rep, filter_name, filter_args = {})
        @rule_memory << [:filter, filter_name, filter_args]
      end

      def layout(_rep, layout_identifier, extra_filter_args = nil)
        if extra_filter_args
          @rule_memory << [:layout, layout_identifier, extra_filter_args]
        else
          @rule_memory << [:layout, layout_identifier]
        end
      end

      def snapshot(_rep, snapshot_name, final: true)
        @rule_memory << [:snapshot, snapshot_name, final: final]

        # Count
        existing = Set.new
        names = @rule_memory.select { |r| r[0] == :snapshot }.map { |r| r[1] }
        names.each do |n|
          if existing.include?(n)
            raise Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName.new(@item_rep, snapshot_name)
          end
          existing << n
        end
      end

      def record_write(_rep, path)
        @rule_memory << [:write, path]
      end
    end
  end
end
