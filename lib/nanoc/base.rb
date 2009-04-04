module Nanoc

  autoload :Asset,              'nanoc/base/asset'
  autoload :AssetDefaults,      'nanoc/base/asset_defaults'
  autoload :AssetRep,           'nanoc/base/asset_rep'
  autoload :BinaryFilter,       'nanoc/base/binary_filter'
  autoload :Code,               'nanoc/base/code'
  autoload :Compiler,           'nanoc/base/compiler'
  autoload :DataSource,         'nanoc/base/data_source'
  autoload :Defaults,           'nanoc/base/defaults'
  autoload :Filter,             'nanoc/base/filter'
  autoload :Layout,             'nanoc/base/layout'
  autoload :NotificationCenter, 'nanoc/base/notification_center'
  autoload :Page,               'nanoc/base/page'
  autoload :PageDefaults,       'nanoc/base/page_defaults'
  autoload :PageRep,            'nanoc/base/page_rep'
  autoload :Plugin,             'nanoc/base/plugin'
  autoload :Proxy,              'nanoc/base/proxy'
  autoload :Router,             'nanoc/base/router'
  autoload :Site,               'nanoc/base/site'
  autoload :Template,           'nanoc/base/template'

  require 'nanoc/base/core_ext'
  require 'nanoc/base/proxies'

end
