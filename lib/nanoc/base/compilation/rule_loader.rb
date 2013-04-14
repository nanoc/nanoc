# encoding: utf-8

module Nanoc

  # Loads the rules from the Rules file into memory
  #
  # @api private
  class RuleLoader

    # TODO remove me (necessary for storing checksum for rules)
    attr_reader :rule_data

    # @param [RulesCollection] rules_collection The rules collection to load
    #   the rules into
    def initialize(rules_collection)
      @rules_collection = rules_collection
    end

    # @return [String] The name of the Rules filename
    def rules_filename
      'Rules'
    end

    # Loads the Rules
    #
    # @return [void]
    def load
      # Get rule data
      if !File.file?(self.rules_filename)
        raise Nanoc::Errors::NoRulesFileFound.new
      end
      @rule_data = File.read(self.rules_filename)

      # Load DSL
      dsl = Nanoc::CompilerDSL.new(@rules_collection)
      dsl.instance_eval(@rule_data, "./#{self.rules_filename}")
    end

  end

end
