# encoding: utf-8

module Nanoc::Extra::Checking::Checks

  autoload 'CSS',           'nanoc/extra/checking/checks/css'
  autoload 'ExternalLinks', 'nanoc/extra/checking/checks/external_links'
  autoload 'HTML',          'nanoc/extra/checking/checks/html'
  autoload 'InternalLinks', 'nanoc/extra/checking/checks/internal_links'
  autoload 'Stale',         'nanoc/extra/checking/checks/stale'

  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::CSS',           :css
  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::ExternalLinks', :external_links
  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::ExternalLinks', :elinks
  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::HTML',          :html
  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::InternalLinks', :internal_links
  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::InternalLinks', :ilinks
  Nanoc::Extra::Checking::Check.register '::Nanoc::Extra::Checking::Checks::Stale',         :stale

end
