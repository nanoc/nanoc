require_relative 'checks/w3c_validator'

# @api private
module Nanoc::Checking::Checks
  autoload 'CSS',           'nanoc/checking/checks/css'
  autoload 'ExternalLinks', 'nanoc/checking/checks/external_links'
  autoload 'HTML',          'nanoc/checking/checks/html'
  autoload 'InternalLinks', 'nanoc/checking/checks/internal_links'
  autoload 'Stale',         'nanoc/checking/checks/stale'
  autoload 'MixedContent',  'nanoc/checking/checks/mixed_content'

  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::CSS',           :css
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::ExternalLinks', :external_links
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::ExternalLinks', :elinks
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::HTML',          :html
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::InternalLinks', :internal_links
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::InternalLinks', :ilinks
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::Stale',         :stale
  Nanoc::Checking::Check.register '::Nanoc::Checking::Checks::MixedContent',  :mixed_content
end
