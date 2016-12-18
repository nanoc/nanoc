# @api private
module Nanoc::Int
  autoload 'Compiler',             'nanoc/base/compilation/compiler'
  autoload 'OutdatednessChecker',  'nanoc/base/compilation/outdatedness_checker'
  autoload 'OutdatednessReasons',  'nanoc/base/compilation/outdatedness_reasons'
  autoload 'OutdatednessRule',     'nanoc/base/compilation/outdatedness_rule'
  autoload 'OutdatednessRules',    'nanoc/base/compilation/outdatedness_rule'
end

require_relative 'base/core_ext'
require_relative 'base/contracts_support'
require_relative 'base/memoization'
require_relative 'base/plugin_registry'
require_relative 'base/error'
require_relative 'base/errors'

require_relative 'base/entities'
require_relative 'base/feature'
require_relative 'base/repos'
require_relative 'base/services'
require_relative 'base/views'
