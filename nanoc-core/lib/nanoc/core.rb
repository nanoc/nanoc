# frozen_string_literal: true

# Ruby stdlib
require 'base64'
require 'fiber'
require 'find'
require 'singleton'
require 'tmpdir'
require 'yaml'
require 'zlib'

# External gems
require 'concurrent-ruby'
require 'json_schema'
require 'ddmetrics'
require 'ddplugin'
require 'immutable'
require 'memo_wise'
require 'slow_enumerator_tools'
require 'tty-platform'
require 'zeitwerk'

# External gems (optional)
begin
  require 'clonefile'
rescue LoadError
  # ignore
end

module Nanoc
  module Core
    # Similar to `nil` except that it can only be compared against using
    # `UNDEFINED.equal?(x)`. Used in places where `nil` already has meaning, and
    # thus cannot be used to mean the presence of nothing.
    UNDEFINED = Object.new

    def UNDEFINED.inspect
      '<UNDEFINED>'
    end

    def UNDEFINED.to_s
      inspect
    end

    # @return [String] A string containing information about this Nanoc version
    #   and its environment (Ruby engine and version, Rubygems version if any).
    #
    # @api private
    def self.version_information
      "Nanoc #{Nanoc::Core::VERSION} © 2007–… Denis Defreyne.\n" \
      "Running #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) on #{RUBY_PLATFORM} with RubyGems #{Gem::VERSION}.\n"
    end

    # @return [Boolean] True if the current platform is Windows, false otherwise.
    #
    # @api private
    def self.on_windows?
      @_on_windows ||= TTY::Platform.new.windows?
    end
  end
end

inflector_class = Class.new(Zeitwerk::Inflector) do
  def camelize(basename, abspath)
    case basename
    when 'version'
      'VERSION'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = inflector_class.new
loader.push_dir(__dir__ + '/..')
loader.ignore(__dir__ + '/../nanoc-core.rb')
loader.ignore(__dir__ + '/core/core_ext')
loader.setup
loader.eager_load

require_relative 'core/core_ext/array'
require_relative 'core/core_ext/hash'
require_relative 'core/core_ext/string'
