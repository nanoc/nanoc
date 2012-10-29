# encoding: utf-8

module Nanoc::Extra

  autoload 'AutoCompiler',      'nanoc/extra/auto_compiler'
  autoload 'Checking',          'nanoc/extra/checking'
  autoload 'CHiCk',             'nanoc/extra/chick'
  autoload 'LinkCollector',     'nanoc/extra/link_collector.rb'
  autoload 'Pruner',            'nanoc/extra/pruner'
  autoload 'Validators',        'nanoc/extra/validators'

  # Deprecated; use {Nanoc::Context} instead
  # TODO [in nanoc 4.0] remove me
  Context = ::Nanoc::Context

  # Deprecated
  # TODO [in nanoc 4.0] remove me
  autoload 'FileProxy',         'nanoc/extra/file_proxy'

end

require 'nanoc/extra/core_ext'
require 'nanoc/extra/deployer'
require 'nanoc/extra/deployers'
require 'nanoc/extra/vcs'
require 'nanoc/extra/vcses'
