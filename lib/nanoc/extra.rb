require 'nanoc/checking'
require 'nanoc/deploying'

# @api private
module Nanoc::Extra
  autoload 'LinkCollector',       'nanoc/extra/link_collector.rb'
  autoload 'Piper',               'nanoc/extra/piper'
  autoload 'JRubyNokogiriWarner', 'nanoc/extra/jruby_nokogiri_warner'

  # @deprecated
  Checking = Nanoc::Checking

  # @deprecated
  Deployer = Nanoc::Deploying::Deployer
end

require 'nanoc/extra/core_ext'
