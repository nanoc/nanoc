module Nanoc
  autoload 'Error',                'nanoc/base/error'
  autoload 'Filter',               'nanoc/base/compilation/filter'

  # TODO: move this elsewhere
  module RuleDSL
    autoload 'CompilerDSL',          'nanoc/base/rule_dsl/compiler_dsl'
  end
end

# @api private
module Nanoc::Int
  # Load helper classes
  autoload 'Context',              'nanoc/base/context'
  autoload 'Checksummer',          'nanoc/base/checksummer'
  autoload 'DirectedGraph',        'nanoc/base/directed_graph'
  autoload 'Errors',               'nanoc/base/errors'
  autoload 'Memoization',          'nanoc/base/memoization'
  autoload 'PluginRegistry',       'nanoc/base/plugin_registry'

  # Load rule DSL classes
  autoload 'RuleDSLActionProvider', 'nanoc/base/rule_dsl/provider'
  autoload 'RecordingExecutor',    'nanoc/base/rule_dsl/recording_executor'
  autoload 'RuleContext',          'nanoc/base/rule_dsl/rule_context'
  autoload 'RuleMemoryCalculator', 'nanoc/base/rule_dsl/rule_memory_calculator'
  autoload 'Rule',                 'nanoc/base/rule_dsl/rule'
  autoload 'RulesCollection',      'nanoc/base/rule_dsl/rules_collection'
  autoload 'RulesLoader',          'nanoc/base/rule_dsl/rules_loader'

  # Load compilation classes
  autoload 'Compiler',             'nanoc/base/compilation/compiler'
  autoload 'DependencyTracker',    'nanoc/base/compilation/dependency_tracker'
  autoload 'ItemRepRepo',          'nanoc/base/compilation/item_rep_repo'
  autoload 'OutdatednessChecker',  'nanoc/base/compilation/outdatedness_checker'
  autoload 'OutdatednessReasons',  'nanoc/base/compilation/outdatedness_reasons'
end

require_relative 'base/core_ext'

require_relative 'base/entities'
require_relative 'base/repos'
require_relative 'base/services'
require_relative 'base/views'
