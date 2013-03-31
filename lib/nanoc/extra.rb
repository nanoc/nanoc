# encoding: utf-8

module Nanoc::Extra

  autoload 'AutoCompiler',      'nanoc/extra/auto_compiler'
  autoload 'Checking',          'nanoc/extra/checking'
  autoload 'LinkCollector',     'nanoc/extra/link_collector.rb'
  autoload 'Pruner',            'nanoc/extra/pruner'
  autoload 'Validators',        'nanoc/extra/validators'

end

require 'nanoc/extra/core_ext'
require 'nanoc/extra/deployer'
require 'nanoc/extra/deployers'
