# encoding: utf-8

module Nanoc

  # Keeps track of the rules in a site.
  #
  # @api private
  class RulesCollection

    extend Nanoc::Memoization

    # @return [Array<Nanoc::Rule>] The list of item compilation rules that
    #   will be used to compile items.
    attr_reader :item_compilation_rules

    # The hash containing layout-to-filter mapping rules. This hash is
    # ordered: iterating over the hash will happen in insertion order.
    #
    # @return [Hash] The layout-to-filter mapping rules
    attr_reader :layout_filter_mapping

    # @return [Proc] The code block that will be executed after all data is
    #   loaded but before the site is compiled
    attr_accessor :preprocessor

    def initialize
      @item_compilation_rules  = []
      @layout_filter_mapping   = {}
    end

    # Add the given rule to the list of item compilation rules.
    #
    # @param [Nanoc::Rule] rule The item compilation rule to add
    #
    # @return [void]
    def add_item_compilation_rule(rule)
      @item_compilation_rules << rule
    end

    # @param [Nanoc::Item] item The item for which the compilation rules
    #   should be retrieved
    #
    # @return [Array] The list of item compilation rules for the given item
    def item_compilation_rules_for(item)
      @item_compilation_rules.select { |r| r.applicable_to?(item) }
    end

    # Finds the first matching compilation rule for the given item
    # representation.
    #
    # @param [Nanoc::ItemRep] rep The item rep for which to fetch the rule
    #
    # @return [Nanoc::Rule, nil] The compilation rule for the given item rep,
    #   or nil if no rules have been found
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Finds the filter name and arguments to use for the given layout.
    #
    # @param [Nanoc::Layout] layout The layout for which to fetch the filter.
    #
    # @return [Array, nil] A tuple containing the filter name and the filter
    #   arguments for the given layout.
    def filter_for_layout(layout)
      @layout_filter_mapping.each_pair do |layout_pattern, filter_name_and_args|
        if layout_pattern.match?(layout.identifier)
          return filter_name_and_args
        end
      end
      nil
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @return [Object] An unique reference to this object
    def reference
      :rules
    end

    def inspect
      "<#{self.class}>"
    end

  end

end
