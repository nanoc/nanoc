# encoding: utf-8

module Nanoc

  require 'nanoc/base/core_ext'
  require 'nanoc/base/ordered_hash'

  # Load helper classes
  autoload 'Context',              'nanoc/base/context'
  autoload 'DirectedGraph',        'nanoc/base/directed_graph'
  autoload 'Errors',               'nanoc/base/errors'
  autoload 'Memoization',          'nanoc/base/memoization'
  autoload 'NotificationCenter',   'nanoc/base/notification_center'
  autoload 'PluginRegistry',       'nanoc/base/plugin_registry'
  autoload 'Store',                'nanoc/base/store'

  # Load source data classes
  autoload 'CodeSnippet',          'nanoc/base/source_data/code_snippet'
  autoload 'Configuration',        'nanoc/base/source_data/configuration'
  autoload 'DataSource',           'nanoc/base/source_data/data_source'
  autoload 'Item',                 'nanoc/base/source_data/item'
  autoload 'Layout',               'nanoc/base/source_data/layout'
  autoload 'Site',                 'nanoc/base/source_data/site'

  # Load result data classes
  autoload 'ItemRep',              'nanoc/base/result_data/item_rep'

  # Load compilation classes
  autoload 'ChecksumStore',        'nanoc/base/compilation/checksum_store'
  autoload 'CompiledContentCache', 'nanoc/base/compilation/compiled_content_cache'
  autoload 'Compiler',             'nanoc/base/compilation/compiler'
  autoload 'CompilerDSL',          'nanoc/base/compilation/compiler_dsl'
  autoload 'DependencyTracker',    'nanoc/base/compilation/dependency_tracker'
  autoload 'Filter',               'nanoc/base/compilation/filter'
  autoload 'ItemRepProxy',         'nanoc/base/compilation/item_rep_proxy'
  autoload 'ItemRepRecorderProxy', 'nanoc/base/compilation/item_rep_recorder_proxy'
  autoload 'OutdatednessChecker',  'nanoc/base/compilation/outdatedness_checker'
  autoload 'OutdatednessReasons',  'nanoc/base/compilation/outdatedness_reasons'
  autoload 'Rule',                 'nanoc/base/compilation/rule'
  autoload 'RuleContext',          'nanoc/base/compilation/rule_context'
  autoload 'RuleMemoryCalculator', 'nanoc/base/compilation/rule_memory_calculator'
  autoload 'RuleMemoryStore',      'nanoc/base/compilation/rule_memory_store'
  autoload 'RulesCollection',      'nanoc/base/compilation/rules_collection'

  # Deprecated; use PluginRepository instead
  # TODO [in nanoc 4.0] remove me
  autoload 'Plugin',               'nanoc/base/plugin_registry'

end
