module Nanoc::RuleDSL
  # Calculates rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryCalculator
    extend Nanoc::Int::Memoization

    class UnsupportedObjectTypeException < ::Nanoc::Error
      def initialize(obj)
        super("Do not know how to calculate the rule memory for #{obj.inspect}")
      end
    end

    class NoRuleMemoryForLayoutException < ::Nanoc::Error
      def initialize(layout)
        super("There is no layout rule specified for #{layout.inspect}")
      end
    end

    class NoRuleMemoryForItemRepException < ::Nanoc::Error
      def initialize(item)
        super("There is no compilation rule specified for #{item.inspect}")
      end
    end

    class PathWithoutInitialSlashError < ::Nanoc::Error
      def initialize(rep, basic_path)
        super("The path returned for the #{rep.inspect} item representation, “#{basic_path}”, does not start with a slash. Please ensure that all routing rules return a path that starts with a slash.")
      end
    end

    # @api private
    attr_accessor :rules_collection

    # @param [Nanoc::Int::Site] site
    # @param [Nanoc::RuleDSL::RulesCollection] rules_collection
    def initialize(site:, rules_collection:)
      @site = site
      @rules_collection = rules_collection
    end

    # @param [#reference] obj
    #
    # @return [Nanoc::Int::RuleMemory]
    def [](obj)
      case obj
      when Nanoc::Int::ItemRep
        new_rule_memory_for_rep(obj)
      when Nanoc::Int::Layout
        new_rule_memory_for_layout(obj)
      else
        raise UnsupportedObjectTypeException.new(obj)
      end
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation for which to fetch
    #   the list of snapshots
    #
    # @return [Array] A list of snapshots, represented as arrays where the
    #   first element is the snapshot name (a Symbol) and the last element is
    #   a Boolean indicating whether the snapshot is final or not
    def snapshots_defs_for(rep)
      self[rep].snapshot_actions.map do |a|
        Nanoc::Int::SnapshotDef.new(a.snapshot_name, a.final?)
      end
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation to get the rule
    #   memory for
    #
    # @return [Nanoc::Int::RuleMemory]
    def new_rule_memory_for_rep(rep)
      dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
      view_context = @site.compiler.compilation_context.create_view_context(dependency_tracker)

      rule_memory = Nanoc::Int::RuleMemory.new(rep)
      executor = Nanoc::RuleDSL::RecordingExecutor.new(rule_memory)
      rule = @rules_collection.compilation_rule_for(rep)

      unless rule
        raise NoRuleMemoryForItemRepException.new(rep)
      end

      executor.snapshot(:raw)
      rule.apply_to(rep, executor: executor, site: @site, view_context: view_context)
      if rule_memory.any_layouts?
        executor.snapshot(:post)
      end
      unless rule_memory.snapshot_actions.any? { |sa| sa.snapshot_name == :last }
        executor.snapshot(:last)
      end

      assign_paths_to_mem(rule_memory, rep: rep)
    end

    # @param [Nanoc::Int::Layout] layout
    #
    # @return [Nanoc::Int::RuleMemory]
    def new_rule_memory_for_layout(layout)
      res = @rules_collection.filter_for_layout(layout)

      unless res
        raise NoRuleMemoryForLayoutException.new(layout)
      end

      Nanoc::Int::RuleMemory.new(layout).tap do |rm|
        rm.add_filter(res[0], res[1])
      end
    end

    def assign_paths_to_mem(mem, rep:)
      mem.map do |action|
        if action.is_a?(Nanoc::Int::ProcessingActions::Snapshot) && action.path.nil? && action.final?
          path_from_rules = basic_path_from_rules_for(rep, action.snapshot_name)
          if path_from_rules
            action.copy(path: path_from_rules.to_s)
          else
            action
          end
        else
          action
        end
      end
    end

    # FIXME: ugly
    def basic_path_from_rules_for(rep, snapshot_name)
      routing_rules = @rules_collection.routing_rules_for(rep)
      routing_rule = routing_rules[snapshot_name]
      return nil if routing_rule.nil?

      dependency_tracker = Nanoc::Int::DependencyTracker::Null.new
      view_context = Nanoc::ViewContext.new(reps: nil, items: nil, dependency_tracker: dependency_tracker, compilation_context: nil)
      basic_path = routing_rule.apply_to(rep, executor: nil, site: @site, view_context: view_context)
      if basic_path && !basic_path.start_with?('/')
        raise PathWithoutInitialSlashError.new(rep, basic_path)
      end
      basic_path
    end
  end
end
