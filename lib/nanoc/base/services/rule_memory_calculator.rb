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
      self[rep].select { |e| e[0] == :snapshot }.map do |e|
        Nanoc::Int::SnapshotDef.new(e[1], e[2].fetch(:final, true))
      end
    end

    # @param [Nanoc::Int::ItemRep] rep The item representation to get the rule
    #   memory for
    #
    # @return [Array] The rule memory for the given item representation
    #
    # @api private
    def new_rule_memory_for_rep(rep)
      executor = Nanoc::Int::RecordingExecutor.new
      @rules_collection
        .compilation_rule_for(rep)
        .apply_to(rep, reps: nil, executor: executor, site: @site)
      executor.record_write(rep, rep.path)
      make_rule_memory_serializable(executor.rule_memory)
    end

    # Makes the given rule memory serializable by calling
    # `Nanoc::Int::Checksummer#calc` on the filter arguments, so that objects such as
    # classes and filenames can be serialized.
    #
    # @param [Array] rs The rule memory for a certain item rep
    #
    # @return [Array] The serializable rule memory
    #
    # @api private
    def make_rule_memory_serializable(rs)
      rs.map do |r|
        if r[0] == :filter
          [r[0], r[1], r[2].to_a.map { |a| Nanoc::Int::Checksummer.calc(a) }]
        else
          r
        end
      end
    end
  end
end
