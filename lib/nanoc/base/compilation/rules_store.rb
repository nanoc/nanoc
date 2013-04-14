# encoding: utf-8

module Nanoc

  # Loads the rules.
  #
  # @abstract Subclasses must implement {#load_rules}.
  class RulesStore

    extend Nanoc::PluginRegistry::PluginMethods

    # @return [RulesCollction] The rules collection
    attr_reader :rules_collection

    # @param [RulesCollection] rules_collection A blank rules collection to
    #   load the rules into
    def initialize(rules_collection)
      @rules_collection = rules_collection
    end

    # Loads the rules into the rules collection.
    #
    # @return [void]
    #
    # @abstract
    def load_rules
      raise NotImplementedError, "Subclasses must implement #load_rules"
    end

  end

end
