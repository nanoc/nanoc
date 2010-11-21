# encoding: utf-8

module Nanoc3

  # The current nanoc version.
  VERSION = '3.1.6'

end

# Load requirements
require 'yaml'
require 'fileutils'

# Load nanoc
require 'nanoc3/base'
require 'nanoc3/extra'
require 'nanoc3/data_sources'
require 'nanoc3/filters'
require 'nanoc3/helpers'
