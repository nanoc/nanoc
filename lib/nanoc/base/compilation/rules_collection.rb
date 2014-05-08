# encoding: utf-8

module Nanoc

  # Keeps track of the rules in a site.
  #
  # @api private
  class RulesCollection

    # @return [String] the contents of the Rules file
    #
    # @api private
    attr_accessor :data

    extend Nanoc::Memoization

    # @return [Array<Nanoc::Rule>] The list of item compilation rules that
    #   will be used to compile items.
    attr_reader :item_compilation_rules

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

    def initialize
      @item_compilation_rules = []
      @item_routing_rules     = []
      @layout_filter_mapping  = {}
      @preprocessors          = {}
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

    # Loads this site’s rules.
    #
    # @return [void]
    def load
      # Find rules file
      rules_filenames = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ]
      rules_filename = rules_filenames.find { |f| File.file?(f) }
      raise Nanoc::Errors::NoRulesFileFound.new if rules_filename.nil?

      parse(rules_filename)
    end

    def parse(rules_filename)
      rules_filename = File.absolute_path(rules_filename)

      # Get rule data
      @data = File.read(rules_filename)

      old_rules_filename = dsl.rules_filename
      dsl.rules_filename = rules_filename
      dsl.instance_eval(@data, rules_filename)
      dsl.rules_filename = old_rules_filename
    end

    # Unloads this site’s rules.
    #
    # @return [void]
    def unload
      @item_compilation_rules = []
      @item_routing_rules     = []
      @layout_filter_mapping  = {}
      @preprocessors          = {}
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

    # @return [String] The checksum for this object. If its contents change,
    #   the checksum will change as well.
    def checksum
      Nanoc::Checksummer.calc(self)
    end

    def inspect
      "<#{self.class}>"
    end

  end

end
