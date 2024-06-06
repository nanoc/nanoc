# frozen_string_literal: true

module Nanoc::RuleDSL
  class ActionSequenceCalculator
    class UnsupportedObjectTypeException < ::Nanoc::Error
      def initialize(obj)
        super("Do not know how to calculate the action sequence for #{obj.inspect}")
      end
    end

    class NoActionSequenceForLayoutException < ::Nanoc::Error
      def initialize(layout)
        super("There is no layout rule specified for #{layout.inspect}")
      end
    end

    class NoActionSequenceForItemRepException < ::Nanoc::Error
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

    # @param [Nanoc::Core::Site] site
    # @param [Nanoc::RuleDSL::RulesCollection] rules_collection
    def initialize(site:, rules_collection:)
      @site = site
      @rules_collection = rules_collection
    end

    # @param [#reference] obj
    #
    # @return [Nanoc::Core::ActionSequence]
    def [](obj)
      case obj
      when Nanoc::Core::ItemRep
        new_action_sequence_for_rep(obj)
      when Nanoc::Core::Layout
        new_action_sequence_for_layout(obj)
      else
        raise UnsupportedObjectTypeException.new(obj)
      end
    end

    def new_action_sequence_for_rep(rep)
      view_context =
        Nanoc::Core::ViewContextForPreCompilation.new(items: @site.items)

      recorder = Nanoc::RuleDSL::ActionRecorder.new(rep)
      rule = @rules_collection.compilation_rule_for(rep)

      unless rule
        raise NoActionSequenceForItemRepException.new(rep)
      end

      recorder.snapshot(:raw)
      rule.apply_to(rep, recorder:, site: @site, view_context:)
      recorder.snapshot(:post) if recorder.any_layouts?
      recorder.snapshot(:last)
      recorder.snapshot(:pre) unless recorder.pre_snapshot?

      copy_paths_from_routing_rules(
        compact_snapshots(recorder.action_sequence),
        recorder.snapshots_for_which_to_skip_routing_rule,
        rep:,
      )
    end

    # @param [Nanoc::Core::Layout] layout
    #
    # @return [Nanoc::Core::ActionSequence]
    def new_action_sequence_for_layout(layout)
      res = @rules_collection.filter_for_layout(layout)

      unless res
        raise NoActionSequenceForLayoutException.new(layout)
      end

      Nanoc::Core::ActionSequenceBuilder.build do |b|
        b.add_filter(res[0], res[1])
      end
    end

    def compact_snapshots(seq)
      actions = []
      seq.actions.each do |action|
        if [actions.last, action].all? { |a| a.is_a?(Nanoc::Core::ProcessingActions::Snapshot) }
          actions[-1] = actions.last.update(snapshot_names: action.snapshot_names, paths: action.paths)
        else
          actions << action
        end
      end
      Nanoc::Core::ActionSequence.new(actions:)
    end

    def copy_paths_from_routing_rules(seq, snapshots_for_which_to_skip_routing_rule, rep:)
      # NOTE: This assumes that `seq` is compacted, i.e. there are no two consecutive snapshot actions.

      seq.map do |action|
        # Only potentially modify snapshot actions
        next action unless action.is_a?(Nanoc::Core::ProcessingActions::Snapshot)

        # If any of the action’s snapshot are explicitly marked as excluded from
        # getting a path from a routing rule, then ignore routing rules.
        next action if snapshots_for_which_to_skip_routing_rule.intersect?(Set.new(action.snapshot_names))

        # If this action already has paths that don’t come from routing rules,
        # then don’t add more to them.
        next action unless action.paths.empty?

        # For each snapshot name, find a path from a routing rule. The routing
        # rule might return nil, so we need #compact.
        paths = action.snapshot_names.map { |sn| basic_path_from_rules_for(rep, sn) }.compact
        action.update(snapshot_names: [], paths:)
      end
    end

    # FIXME: ugly
    def basic_path_from_rules_for(rep, snapshot_name)
      routing_rules = @rules_collection.routing_rules_for(rep)
      routing_rule = routing_rules[snapshot_name]
      return nil if routing_rule.nil?

      view_context =
        Nanoc::Core::ViewContextForPreCompilation.new(items: @site.items)

      basic_path =
        routing_rule.apply_to(
          rep,
          site: @site,
          view_context:,
        )

      if basic_path && !basic_path.start_with?('/')
        raise PathWithoutInitialSlashError.new(rep, basic_path)
      end

      basic_path
    end
  end
end
