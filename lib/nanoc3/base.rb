# encoding: utf-8

module Nanoc3

  require 'nanoc3/base/core_ext'
  require 'nanoc3/base/ordered_hash'

  autoload 'CodeSnippet',         'nanoc3/base/code_snippet'
  autoload 'Compiler',            'nanoc3/base/compiler'
  autoload 'CompilerDSL',         'nanoc3/base/compiler_dsl'
  autoload 'Config',              'nanoc3/base/config'
  autoload 'DataSource',          'nanoc3/base/data_source'
  autoload 'DependencyTracker',   'nanoc3/base/dependency_tracker'
  autoload 'Errors',              'nanoc3/base/errors'
  autoload 'Filter',              'nanoc3/base/filter'
  autoload 'Item',                'nanoc3/base/item'
  autoload 'ItemRep',             'nanoc3/base/item_rep'
  autoload 'Layout',              'nanoc3/base/layout'
  autoload 'NotificationCenter',  'nanoc3/base/notification_center'
  autoload 'Plugin',              'nanoc3/base/plugin'
  autoload 'PreprocessorContext', 'nanoc3/base/preprocessor_context'
  autoload 'Rule',                'nanoc3/base/rule'
  autoload 'RuleContext',         'nanoc3/base/rule_context'
  autoload 'Site',                'nanoc3/base/site'

end
