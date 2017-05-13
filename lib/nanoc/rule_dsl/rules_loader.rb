# frozen_string_literal: true

module Nanoc::RuleDSL
  # @api private
  class RulesLoader
    def initialize(config, rules_collection)
      @dsl = Nanoc::RuleDSL::CompilerDSL.new(rules_collection, config)
    end

    def load
      # Find rules file
      rules_filenames = ['Rules', 'rules', 'Rules.rb', 'rules.rb']
      rules_filename = rules_filenames.find { |f| File.file?(f) }
      raise Nanoc::Int::Errors::NoRulesFileFound.new if rules_filename.nil?

      parse(rules_filename)
    end

    def parse(rules_filename)
      rules_filename = File.absolute_path(rules_filename)

      # Get rule data
      data = File.read(rules_filename)

      old_rules_filename = @dsl.rules_filename
      @dsl.rules_filename = rules_filename
      @dsl.instance_eval(data, rules_filename)
      @dsl.rules_filename = old_rules_filename
    end
  end
end
