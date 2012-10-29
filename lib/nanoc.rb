# encoding: utf-8

module Nanoc

  # The current nanoc version.
  VERSION = '3.5.0'

  # @return [String] A string containing information about this nanoc version
  #   and its environment (Ruby engine and version, Rubygems version if any).
  def self.version_information
    gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : "without RubyGems"
    engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    res = ''
    res << "nanoc #{Nanoc::VERSION} © 2007-2012 Denis Defreyne.\n"
    res << "Running #{engine} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} #{gem_info}.\n"
    res
  end

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
