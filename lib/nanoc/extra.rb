# @api private
module Nanoc::Extra
  autoload 'Checking',            'nanoc/extra/checking'
  autoload 'FilesystemTools',     'nanoc/extra/filesystem_tools'
  autoload 'LinkCollector',       'nanoc/extra/link_collector.rb'
  autoload 'Pruner',              'nanoc/extra/pruner'
  autoload 'Piper',               'nanoc/extra/piper'
  autoload 'JRubyNokogiriWarner', 'nanoc/extra/jruby_nokogiri_warner'
end

require 'nanoc/extra/core_ext'
require 'nanoc/extra/deployer'
require 'nanoc/extra/deployers'
require 'nanoc/extra/fish_autocompletion'
