module Nanoc3

  # The current nanoc version.
  VERSION = '3.0'

end

# Load requirements
require 'yaml'
require 'fileutils'

# Load nanoc
require 'nanoc3/base'
require 'nanoc3/extra'
require 'nanoc3/data_sources'
require 'nanoc3/filters'
require 'nanoc3/routers'
require 'nanoc3/helpers'
