module Nanoc
  # @api private
  module RuleDSL
    autoload 'CompilerDSL',           'nanoc/rule_dsl/compiler_dsl'
    autoload 'ActionProvider',        'nanoc/rule_dsl/action_provider'
    autoload 'RecordingExecutor',     'nanoc/rule_dsl/recording_executor'
    autoload 'RuleContext',           'nanoc/rule_dsl/rule_context'
    autoload 'RuleMemoryCalculator',  'nanoc/rule_dsl/rule_memory_calculator'
    autoload 'Rule',                  'nanoc/rule_dsl/rule'
    autoload 'RulesCollection',       'nanoc/rule_dsl/rules_collection'
    autoload 'RulesLoader',           'nanoc/rule_dsl/rules_loader'
  end
end
