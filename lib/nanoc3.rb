# encoding: utf-8

module Nanoc3

  # The current nanoc version.
  VERSION = '3.2.0a3'

end

# Switch #require for a faster variant
require 'set'
$_nanoc_requires ||= Set.new
module Kernel
  alias_method :nanoc_original_require, :require
  def require(r)
    return if $_nanoc_requires.include?(r)
    nanoc_original_require(r)
    $_nanoc_requires << r
  end
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
