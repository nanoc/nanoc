module Nanoc
  require 'nanoc/base/core_ext'

  autoload 'Error',                'nanoc/base/error'
  autoload 'DataSource',           'nanoc/base/source_data/data_source'
  autoload 'Filter',               'nanoc/base/compilation/filter'
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
  autoload 'IdentifiableCollection', 'nanoc/base/identifiable_collection'

  # Load source data classes
  autoload 'CodeSnippet',          'nanoc/base/source_data/code_snippet'
  autoload 'Configuration',        'nanoc/base/source_data/configuration'
  autoload 'Item',                 'nanoc/base/source_data/item'
  autoload 'Site',                 'nanoc/base/source_data/site'

  # Load result data classes
  autoload 'ItemRep',              'nanoc/base/result_data/item_rep'

  # Load compilation classes
  autoload 'Compiler',             'nanoc/base/compilation/compiler'
  autoload 'CompilerDSL',          'nanoc/base/compilation/compiler_dsl'
  autoload 'DependencyTracker',    'nanoc/base/compilation/dependency_tracker'
  autoload 'OutdatednessChecker',  'nanoc/base/compilation/outdatedness_checker'
  autoload 'OutdatednessReasons',  'nanoc/base/compilation/outdatedness_reasons'
  autoload 'Rule',                 'nanoc/base/compilation/rule'
  autoload 'RuleContext',          'nanoc/base/compilation/rule_context'
  autoload 'RuleMemoryCalculator', 'nanoc/base/compilation/rule_memory_calculator'
  autoload 'ItemRepSelector',      'nanoc/base/compilation/item_rep_selector'
  autoload 'ItemRepRouter',        'nanoc/base/compilation/item_rep_router'
end

require_relative 'base/entities'
require_relative 'base/repos'
require_relative 'base/services'
require_relative 'base/views'
