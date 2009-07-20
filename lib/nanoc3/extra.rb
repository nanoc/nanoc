# encoding: utf-8

module Nanoc3::Extra

  autoload 'AutoCompiler',      'nanoc3/extra/auto_compiler'
  autoload 'CachingHTTPClient', 'nanoc3/extra/caching_http_client'
  autoload 'Context',           'nanoc3/extra/context'
  autoload 'Deployers',         'nanoc3/extra/deployers'
  autoload 'FileProxy',         'nanoc3/extra/file_proxy'
  autoload 'Validators',        'nanoc3/extra/validators'

end

require 'nanoc3/extra/core_ext'
require 'nanoc3/extra/vcs'
require 'nanoc3/extra/vcses'
