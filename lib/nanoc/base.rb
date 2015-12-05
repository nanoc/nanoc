module Nanoc
  autoload 'Error',                'nanoc/base/error'
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
