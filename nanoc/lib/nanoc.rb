# frozen_string_literal: true

# Load external dependencies
require 'addressable'
require 'colored'
require 'ddplugin'
require 'json'
require 'parallel'

module Nanoc
  # @return [String] A string containing information about this Nanoc version
  #   and its environment (Ruby engine and version, Rubygems version if any).
  #
  # @api private
  def self.version_information
    "Nanoc #{Nanoc::VERSION} © 2007–2019 Denis Defreyne.\n" \
    "Running #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} with RubyGems #{Gem::VERSION}.\n"
  end

  # @return [Boolean] True if the current platform is Windows, false otherwise.
  #
  # @api private
  def self.on_windows?
    @_on_windows ||= TTY::Platform.new.windows?
  end
end

# Load general requirements
require 'base64'
require 'cgi'
require 'diff/lcs'
require 'diff/lcs/hunk'
require 'digest'
require 'English'
require 'fileutils'
require 'find'
require 'forwardable'
require 'logger'
require 'net/http'
require 'net/https'
require 'open3'
require 'pathname'
require 'set'
require 'singleton'
require 'stringio'
require 'tempfile'
require 'time'
require 'timeout'
require 'tmpdir'
require 'tty-platform'
require 'tty-which'
require 'uri'

# Load extracted Nanoc dependencies
require 'nanoc-core'

# Re-export from Nanoc::Core
Nanoc::Identifier = Nanoc::Core::Identifier
Nanoc::DataSource = Nanoc::Core::DataSource
Nanoc::Filter = Nanoc::Core::Filter

# Load Nanoc
require 'nanoc/version'
require 'nanoc/base'
require 'nanoc/checking'
require 'nanoc/deploying'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/filters'
require 'nanoc/helpers'
require 'nanoc/rule_dsl'
