# frozen_string_literal: true

module Nanoc
  # @api private
  module RuleDSL
  end
end

require_relative 'rule_dsl/errors'
require_relative 'rule_dsl/compiler_dsl'
require_relative 'rule_dsl/action_provider'
require_relative 'rule_dsl/action_recorder'
require_relative 'rule_dsl/action_sequence_calculator'
require_relative 'rule_dsl/rules_collection'
require_relative 'rule_dsl/rules_loader'

require_relative 'rule_dsl/rule_context'
require_relative 'rule_dsl/compilation_rule_context'
require_relative 'rule_dsl/routing_rule_context'

require_relative 'rule_dsl/rule'
require_relative 'rule_dsl/compilation_rule'
require_relative 'rule_dsl/routing_rule'

Nanoc::Core::Checksummer.define_behavior(
  Nanoc::RuleDSL::CompilationRuleContext,
  Nanoc::Core::Checksummer::RuleContextUpdateBehavior,
)

Nanoc::Core::Checksummer.define_behavior(
  Nanoc::RuleDSL::RulesCollection,
  Nanoc::Core::Checksummer::DataUpdateBehavior,
)
