# frozen_string_literal: true

module Nanoc
  # @return [String] A string containing information about this Nanoc version
  #   and its environment (Ruby engine and version, Rubygems version if any).
  #
  # @api private
  def self.version_information
    "Nanoc #{Nanoc::VERSION} © 2007-2017 Denis Defreyne.\n" \
    "Running #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} with RubyGems #{Gem::VERSION}.\n"
  end

  # @return [Boolean] True if the current platform is Windows, false otherwise.
  #
  # @api private
  def self.on_windows?
    RUBY_PLATFORM =~ /windows|bccwin|cygwin|djgpp|mingw|mswin|wince/i
  end
end

# Load external dependencies
require 'hamster'
require 'ref'
require 'ddplugin'
require 'addressable'

# Load general requirements
require 'cgi'
require 'digest'
require 'fiber'
require 'fileutils'
require 'forwardable'
require 'pathname'
require 'pstore'
require 'set'
require 'singleton'
require 'tempfile'
require 'time'
require 'yaml'
require 'uri'
require 'English'

# Load Nanoc
require 'nanoc/version'
require 'nanoc/base'
require 'nanoc/telemetry'
require 'nanoc/checking'
require 'nanoc/deploying'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/filters'
require 'nanoc/helpers'
require 'nanoc/rule_dsl'
