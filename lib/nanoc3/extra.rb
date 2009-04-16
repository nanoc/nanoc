module Nanoc3::Extra

  autoload :AutoCompiler, 'nanoc3/extra/auto_compiler'
  autoload :Context,      'nanoc3/extra/context'
  autoload :FileProxy,    'nanoc3/extra/file_proxy'

end

require 'nanoc3/extra/core_ext'
require 'nanoc3/extra/vcs'
require 'nanoc3/extra/vcses'
