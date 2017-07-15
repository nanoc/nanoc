# frozen_string_literal: true

module Nanoc::RuleDSL
  # Keeps track of the rules in a site.
  #
  # @api private
  class RulesCollection
    # @return [String] the contents of the Rules file
    attr_accessor :data

    # The hash containing layout-to-filter mapping rules. This hash is
    # ordered: iterating over the hash will happen in insertion order.
    #
    # @return [Hash] The layout-to-filter mapping rules
    attr_reader :layout_filter_mapping

    # The hash containing preprocessor code blocks that will be executed after
    #   all data is loaded but before the site is compiled.
    #
    # @return [Hash] The hash containing the preprocessor code blocks that will
    #   be executed after all data is loaded but before the site is compiled
    attr_accessor :preprocessors

    # The hash containing postprocessor code blocks that will be executed after
    #   all data is loaded and the site is compiled.
    #
    # @return [Hash] The hash containing the postprocessor code blocks that will
    #   be executed after all data is loaded and the site is compiled
    attr_accessor :postprocessors

    def initialize
      @item_compilation_rules = []
      @item_routing_rules     = []
      @layout_filter_mapping  = {}
      @preprocessors          = {}
      @postprocessors         = {}
    end

    # Add the given rule to the list of item compilation rules.
    #
    # @param [Nanoc::Int::Rule] rule The item compilation rule to add
    #
    # @return [void]
    def add_item_compilation_rule(rule)
      @item_compilation_rules << rule
    end

    # Add the given rule to the list of item routing rules.
    #
    # @param [Nanoc::Int::Rule] rule The item routing rule to add
    #
    # @return [void]
    def add_item_routing_rule(rule)
      @item_routing_rules << rule
    end

    # @param [Nanoc::Int::Item] item The item for which the compilation rules
    #   should be retrieved
    #
    # @return [Array] The list of item compilation rules for the given item
    def item_compilation_rules_for(item)
      @item_compilation_rules.select { |r| r.applicable_to?(item) }
    end

    # Finds the first matching compilation rule for the given item
    # representation.
    #
    # @param [Nanoc::Int::ItemRep] rep The item rep for which to fetch the rule
    #
    # @return [Nanoc::Int::Rule, nil] The compilation rule for the given item rep,
    #   or nil if no rules have been found
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Returns the list of routing rules that can be applied to the given item
    # representation. For each snapshot, the first matching rule will be
    # returned. The result is a hash containing the corresponding rule for
    # each snapshot.
    #
    # @param [Nanoc::Int::ItemRep] rep The item rep for which to fetch the rules
    #
    # @return [Hash<Symbol, Nanoc::Int::Rule>] The routing rules for the given rep
    def routing_rules_for(rep)
      rules = {}
      @item_routing_rules.each do |rule|
        next unless rule.applicable_to?(rep.item)
        next if rule.rep_name != rep.name
        next if rules.key?(rule.snapshot_name)

        rules[rule.snapshot_name] = rule
      end
      rules
    end

    # Finds the filter name and arguments to use for the given layout.
    #
    # @param [Nanoc::Int::Layout] layout The layout for which to fetch the filter.
    #
    # @return [Array, nil] A tuple containing the filter name and the filter
    #   arguments for the given layout.
    def filter_for_layout(layout)
      @layout_filter_mapping.each_pair do |pattern, filter_name_and_args|
        return filter_name_and_args if pattern.match?(layout.identifier)
      end
      nil
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @return [Object] An unique reference to this object
    def reference
      'rules'
    end

    def inspect
      "<#{self.class}>"
    end
  end
end
