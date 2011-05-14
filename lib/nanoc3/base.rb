# encoding: utf-8

module Nanoc3

  require 'nanoc3/base/core_ext'
  require 'nanoc3/base/ordered_hash'

  # Load helper classes
  autoload 'Context',              'nanoc3/base/context'
  autoload 'DirectedGraph',        'nanoc3/base/directed_graph'
  autoload 'Errors',               'nanoc3/base/errors'
  autoload 'Memoization',          'nanoc3/base/memoization'
  autoload 'NotificationCenter',   'nanoc3/base/notification_center'
  autoload 'PluginRegistry',       'nanoc3/base/plugin_registry'
  autoload 'Store',                'nanoc3/base/store'

  # Load source data classes
  autoload 'CodeSnippet',          'nanoc3/base/source_data/code_snippet'
  autoload 'DataSource',           'nanoc3/base/source_data/data_source'
  autoload 'Item',                 'nanoc3/base/source_data/item'
  autoload 'Layout',               'nanoc3/base/source_data/layout'
  autoload 'Site',                 'nanoc3/base/source_data/site'

  # Load result data classes
  autoload 'ItemRep',              'nanoc3/base/result_data/item_rep'

  # Load compilation classes
  autoload 'ChecksumCalculator',    'nanoc3/base/compilation/checksum_calculator'
  autoload 'ChecksumStore',        'nanoc3/base/compilation/checksum_store'
  autoload 'CompiledContentCache', 'nanoc3/base/compilation/compiled_content_cache'
  autoload 'Compiler',             'nanoc3/base/compilation/compiler'
  autoload 'CompilerDSL',          'nanoc3/base/compilation/compiler_dsl'
  autoload 'DependencyTracker',    'nanoc3/base/compilation/dependency_tracker'
  autoload 'Filter',               'nanoc3/base/compilation/filter'
  autoload 'ItemRepProxy',         'nanoc3/base/compilation/item_rep_proxy'
  autoload 'ItemRepRecorderProxy', 'nanoc3/base/compilation/item_rep_recorder_proxy'
  autoload 'OutdatednessChecker',  'nanoc3/base/compilation/outdatedness_checker'
  autoload 'OutdatednessReasons',  'nanoc3/base/compilation/outdatedness_reasons'
  autoload 'Rule',                 'nanoc3/base/compilation/rule'
  autoload 'RuleContext',          'nanoc3/base/compilation/rule_context'
  autoload 'RuleMemoryCalculator', 'nanoc3/base/compilation/rule_memory_calculator'
  autoload 'RuleMemoryStore',      'nanoc3/base/compilation/rule_memory_store'

  # Deprecated; use PluginRepository instead
  # TODO [in nanoc 4.0] remove me
  autoload 'Plugin',               'nanoc3/base/plugin_registry'

end
