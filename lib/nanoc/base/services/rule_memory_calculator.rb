module Nanoc::Int
  # Calculates rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryCalculator
    extend Nanoc::Int::Memoization

    # @api private
    attr_accessor :rules_collection

    # @param [Nanoc::Int::Site] site
    # @param [Nanoc::Int::RulesCollection] rules_collection
    def initialize(site:, rules_collection:)
      @site = site
      @rules_collection = rules_collection
    end

    # @param [#reference] obj The object to calculate the rule memory for
    #
    # @return [Array] The caluclated rule memory for the given object
    def [](obj)
      result =
        case obj
        when Nanoc::Int::ItemRep
          new_rule_memory_for_rep(obj)
        when Nanoc::Int::Layout
          @rules_collection.filter_for_layout(obj)
        else
          raise "Do not know how to calculate the rule memory for #{obj.inspect}"
        end

      result
    end
    memoize :[]

    # @param [Nanoc::Int::ItemRep] rep The item representation for which to fetch
    #   the list of snapshots
    #
    # @return [Array] A list of snapshots, represented as arrays where the
    #   first element is the snapshot name (a Symbol) and the last element is
    #   a Boolean indicating whether the snapshot is final or not
    def snapshots_defs_for(rep)
      # TODO: Don’t use the serialized form here
      self[rep].select { |e| e[0] == :snapshot }.map do |e|
        Nanoc::Int::SnapshotDef.new(e[1], e[2])
      end
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation to get the rule
    #   memory for
    #
    # @return [Array] The rule memory for the given item representation
    #
    # @api private
    def new_rule_memory_for_rep(rep)
      executor = Nanoc::Int::RecordingExecutor.new(rep)
      @rules_collection
        .compilation_rule_for(rep)
        .apply_to(rep, executor: executor, site: @site, view_context: nil)
      executor.record_write(rep, rep.path)
      executor.rule_memory.serialize
    end
  end
end
