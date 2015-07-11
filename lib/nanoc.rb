module Nanoc
  # @return [String] A string containing information about this Nanoc version
  #   and its environment (Ruby engine and version, Rubygems version if any).
  #
  # @api private
  def self.version_information
    gem_info = defined?(Gem) ? "with RubyGems #{Gem::VERSION}" : 'without RubyGems'
    engine   = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
    res = ''
    res << "Nanoc #{Nanoc::VERSION} © 2007-2015 Denis Defreyne.\n"
    res << "Running #{engine} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} #{gem_info}.\n"
    res
  end

  # @return [Boolean] True if the current platform is Windows, false otherwise.
  #
  # @api private
  def self.on_windows?
    RUBY_PLATFORM =~ /windows|bccwin|cygwin|djgpp|mingw|mswin|wince/i
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
require 'English'

# Load Nanoc
require 'nanoc/version'
require 'nanoc/base'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/filters'
require 'nanoc/helpers'
