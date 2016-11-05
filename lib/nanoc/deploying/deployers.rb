module Nanoc::Deploying
  # @api private
  module Deployers
    autoload 'Fog',   'nanoc/deploying/deployers/fog'
    autoload 'Rsync', 'nanoc/deploying/deployers/rsync'

    Nanoc::Deploying::Deployer.register '::Nanoc::Deploying::Deployers::Fog',   :fog
    Nanoc::Deploying::Deployer.register '::Nanoc::Deploying::Deployers::Rsync', :rsync
  end
end
