# encoding: utf-8

module Nanoc

  # The current nanoc version.
  VERSION = '3.2.0b2'

end

Nanoc3 = Nanoc

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
require 'nanoc/base'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/filters'
require 'nanoc/helpers'
