# @api private
module Nanoc::Extra
  autoload 'LinkCollector',       'nanoc/extra/link_collector.rb'
  autoload 'Pruner',              'nanoc/extra/pruner'
  autoload 'Piper',               'nanoc/extra/piper'
  autoload 'JRubyNokogiriWarner', 'nanoc/extra/jruby_nokogiri_warner'
end

require 'nanoc/extra/core_ext'
