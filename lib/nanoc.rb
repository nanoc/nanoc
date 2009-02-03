module Nanoc

  # The current nanoc version.
  VERSION = '2.2'

end

# Load requirements
begin ; require 'rubygems' ; rescue LoadError ; end
require 'yaml'
require 'fileutils'

# Load nanoc
require 'nanoc/base'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/filters'
require 'nanoc/routers'
require 'nanoc/helpers'
