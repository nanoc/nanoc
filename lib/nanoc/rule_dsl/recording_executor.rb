module Nanoc
  module RuleDSL
    class RecordingExecutor
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
        unless layout_identifier.is_a?(String)
          raise ArgumentError.new('The layout passed to #layout must be a string')
        end

        unless @rule_memory.any_layouts?
          @rule_memory.add_snapshot(:pre, true, nil)
        end

        @rule_memory.add_layout(layout_identifier, extra_filter_args)
      end

      def snapshot(rep, snapshot_name, final: true, path: nil)
        actual_path = final ? (path || basic_path_from_rules_for(rep, snapshot_name)) : nil
        @rule_memory.add_snapshot(snapshot_name, final, actual_path)
      end

      def basic_path_from_rules_for(rep, snapshot_name)
        routing_rules = @rules_collection.routing_rules_for(rep)
        routing_rule = routing_rules[snapshot_name]
        return nil if routing_rule.nil?

        dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
        view_context = Nanoc::ViewContext.new(reps: nil, items: nil, dependency_tracker: dependency_tracker, compiler: nil)
        basic_path = routing_rule.apply_to(rep, executor: nil, site: @site, view_context: view_context)
        if basic_path && !basic_path.start_with?('/')
          raise PathWithoutInitialSlashError.new(rep, basic_path)
        end
        basic_path
      end
    end
  end
end
