# encoding: utf-8

module Nanoc3::Routers

  autoload 'Default',   'nanoc3/routers/default'
  autoload 'NoDirs',    'nanoc3/routers/no_dirs'
  autoload 'Versioned', 'nanoc3/routers/versioned'

  Nanoc3::Router.register '::Nanoc3::Routers::Default',   :default
  Nanoc3::Router.register '::Nanoc3::Routers::NoDirs',    :no_dirs
  Nanoc3::Router.register '::Nanoc3::Routers::Versioned', :versioned

end
