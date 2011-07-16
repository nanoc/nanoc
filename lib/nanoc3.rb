# encoding: utf-8

module Nanoc3

  # The current nanoc version.
  VERSION = '3.2.0b2'

end

# Load general requirements
require 'digest'
require 'enumerator'
require 'fileutils'
require 'forwardable'
require 'pathname'
require 'pstore'
require 'set'
require 'tempfile'
require 'thread'
require 'time'
require 'yaml'

# Load nanoc
require 'nanoc3/base'
require 'nanoc3/extra'
require 'nanoc3/data_sources'
require 'nanoc3/filters'
require 'nanoc3/helpers'
