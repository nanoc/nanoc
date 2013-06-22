# encoding: utf-8

module Nanoc

  # Calculates rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryCalculator

    extend Nanoc::Memoization

    # @option params [Nanoc::RulesCollection] rules_collection The rules
    #   collection
    def initialize(params={})
      @compiler         = params.fetch(:compiler)         { raise ArgumentError, "Required :compiler option is missing" }
      @rules_collection = params.fetch(:rules_collection) { raise ArgumentError, "Required :rules_collection option is missing" }
    end

    # @param [#reference] obj The object to calculate the rule memory for
    #
    # @return [Array] The calculated rule memory for the given object
    def [](obj)
      result = case obj.type
        when :item_rep
          self.new_rule_memory_for_rep(obj)
        when :layout
          self.new_rule_memory_for_layout(obj)
        else
          raise RuntimeError,
            "Do not know how to calculate the rule memory for #{obj.inspect}"
      end

      result
    end
    memoize :[]

    # @param [Nanoc::ItemRep] rep The item representation to get the rule
    #   memory for
    #
    # @return [Array] The rule memory for the given item representation
    def new_rule_memory_for_rep(rep)
      recording_proxy = rep.to_recording_proxy
      @rules_collection.compilation_rule_for(rep).apply_to(recording_proxy, :compiler => @compiler)
      make_rule_memory_serializable(recording_proxy.rule_memory)
    end
    memoize :new_rule_memory_for_rep

    # Makes the given rule memory serializable by calling `#inspect` on the
    # filter arguments, so that objects such as classes and filenames can be
    # serialized.
    #
    # @param [Array] rs The rule memory for a certain item rep
    #
    # @return [Array] The serializable rule memory
    def make_rule_memory_serializable(rs)
      rs.map do |r|
        if r[0] == :filter
          [ r[0], r[1], r[2].to_a.map { |a| a.inspect }  ]
        else
          r
        end
      end
    end

    # @param [Nanoc::Layout] layout The layout to get the rule memory for
    #
    # @return [Array] The rule memory for the given layout
    def new_rule_memory_for_layout(layout)
      @rules_collection.filter_for_layout(layout)
    end
    memoize :new_rule_memory_for_layout

    # @param [Nanoc::ItemRep] rep The item representation for which to fetch
    #   the list of snapshots
    #
    # @return [Array] A list of snapshots, represented as arrays where the
    #   first element is the snapshot name (a Symbol) and the last element is
    #   a Boolean indicating whether the snapshot is final or not
    def snapshots_for(rep)
      mem = new_rule_memory_for_rep(rep)

      names_1 = mem.select { |e| e[0] == :snapshot }.
        map { |e| [ e[1], e[2].fetch(:final, true) ] }

      names_2 = mem.select { |r| r[0] == :write && r[2].has_key?(:snapshot) }.
        map { |r| [ r[2][:snapshot], true ] }

      names_1 + names_2
    end

    def write_paths_for(rep)
      new_rule_memory_for_rep(rep).select { |e| e[0] == :write }.map { |e| e[1].to_s }
    end

    # @param [Nanoc::Item] obj The object for which to check the rule memory
    #
    # @return [Boolean] true if the rule memory for the given object has
    # changed since the last compilation, false otherwise
    def rule_memory_differs_for(obj)
      !rule_memory_store[obj].eql?(self[obj])
    end
    memoize :rule_memory_differs_for

    # @return [Nanoc::RuleMemoryStore] The rule memory store
    def rule_memory_store
      @compiler.rule_memory_store
    end

  end

end
