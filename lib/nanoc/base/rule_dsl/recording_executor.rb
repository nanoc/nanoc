module Nanoc
  module Int
    class RecordingExecutor
      class NonFinalSnapshotWithPathError < ::Nanoc::Error
        def initialize
          super('This call to #snapshot specifies `final: false`, but it also specifies a path, which is an impossible combination.')
        end
      end

      class PathWithoutInitialSlashError < ::Nanoc::Error
        def initialize(rep, basic_path)
          super("The path returned for the #{rep.inspect} item representation, “#{basic_path}”, does not start with a slash. Please ensure that all routing rules return a path that starts with a slash.")
        end
      end

      attr_reader :rule_memory

      def initialize(item_rep, rules_collection, site)
        @item_rep = item_rep
        @rules_collection = rules_collection
        @site = site

        @rule_memory = Nanoc::Int::RuleMemory.new(item_rep)
      end

      def filter(_rep, filter_name, filter_args = {})
        @rule_memory.add_filter(filter_name, filter_args)
      end

      def layout(_rep, layout_identifier, extra_filter_args = {})
        @rule_memory.add_layout(layout_identifier, extra_filter_args)
      end

      def snapshot(rep, snapshot_name, final: true, path: nil)
        actual_path = path || basic_path_from_rules_for(rep, snapshot_name)
        if !final && actual_path
          raise NonFinalSnapshotWithPathError
        end
        @rule_memory.add_snapshot(snapshot_name, final, actual_path)
      end

      def basic_path_from_rules_for(rep, snapshot_name)
        routing_rules = @rules_collection.routing_rules_for(rep)
        routing_rule = routing_rules[snapshot_name]
        return nil if routing_rule.nil?

        basic_path = routing_rule.apply_to(rep, executor: nil, site: @site, view_context: nil)
        if basic_path && !basic_path.start_with?('/')
          raise PathWithoutInitialSlashError.new(rep, basic_path)
        end
        basic_path
      end
    end
  end
end
