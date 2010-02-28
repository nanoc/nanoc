# encoding: utf-8

module Nanoc3::Extra

  autoload 'AutoCompiler',      'nanoc3/extra/auto_compiler'
  autoload 'CHiCk',             'nanoc3/extra/chick'
  autoload 'Deployers',         'nanoc3/extra/deployers'
  autoload 'Validators',        'nanoc3/extra/validators'

  # Deprecated; use {Nanoc3::Context} instead
  # TODO [in nanoc 4.0] remove me
  Context = ::Nanoc3::Context

  # Deprecated
  # TODO [in nanoc 4.0] remove me
  autoload 'FileProxy',         'nanoc3/extra/file_proxy'

end

require 'nanoc3/extra/core_ext'
require 'nanoc3/extra/vcs'
require 'nanoc3/extra/vcses'
