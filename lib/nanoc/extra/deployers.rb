# encoding: utf-8

module Nanoc::Extra

  module Deployers

    autoload 'Fog',   'nanoc/extra/deployers/fog'
    autoload 'Rsync', 'nanoc/extra/deployers/rsync'
    autoload 'Lftp',  'nanoc/extra/deployers/lftp'

    Nanoc::Extra::Deployer.register '::Nanoc::Extra::Deployers::Fog',   :fog
    Nanoc::Extra::Deployer.register '::Nanoc::Extra::Deployers::Rsync', :rsync
    Nanoc::Extra::Deployer.register '::Nanoc::Extra::Deployers::Lftp',  :lftp

  end

end
