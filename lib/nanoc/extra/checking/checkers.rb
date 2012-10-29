# encoding: utf-8

module Nanoc::Extra::Checking::Checkers

  autoload 'CSS',           'nanoc/extra/checking/checkers/css'
  autoload 'ExternalLinks', 'nanoc/extra/checking/checkers/external_links'
  autoload 'HTML',          'nanoc/extra/checking/checkers/html'
  autoload 'InternalLinks', 'nanoc/extra/checking/checkers/internal_links'
  autoload 'Stale',         'nanoc/extra/checking/checkers/stale'

  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::CSS',           :css
  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::ExternalLinks', :external_links
  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::ExternalLinks', :elinks
  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::HTML',          :html
  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::InternalLinks', :internal_links
  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::InternalLinks', :ilinks
  Nanoc::Extra::Checking::Checker.register '::Nanoc::Extra::Checking::Checkers::Stale',         :stale

end
