module Nanoc

  # The current nanoc version.
  VERSION = '2.1'

  # Generic error. Superclass for all nanoc-specific errors.
  class Error < RuntimeError ; end

  module Errors # :nodoc:

    # Error that is raised when a site is loaded that uses a data source with
    # an unknown identifier.
    class UnknownDataSourceError < Error ; end

    # Error that is raised when a site is loaded that uses a data source with
    # an unknown identifier.
    class UnknownRouterError < Error ; end

    # Error that is raised during site compilation when a page uses a layout
    # that is not present in the site.
    class UnknownLayoutError < Error ; end

    # Error that is raised during site compilation when a page uses a filter
    # that is not known.
    class UnknownFilterError < Error ; end

    # Error that is raised during site compilation when a layout is compiled
    # for which the filter cannot be determined. This is similar to the
    # UnknownFilterError, but specific for filters for layouts.
    class CannotDetermineFilterError < Error ; end

    # Error that is raised during site compilation when a page (directly or
    # indirectly) includes its own page content, leading to endless recursion.
    class RecursiveCompilationError < Error ; end

    # Error that is raised when a certain function or feature is used that is
    # no longer supported by nanoc.
    class NoLongerSupportedError < Error ; end

  end

  module BinaryFilters # :nodoc:
  end

  module DataSources # :nodoc:
  end

  module Extensions # :nodoc:
  end

  module Filters # :nodoc:
  end

  module Routers # :nodoc:
  end

  # Requires the given Ruby files at the specified path.
  #
  # +path+:: An array containing path segments. This path is relative to the
  #          directory this file (nanoc.rb) is in. Can contain wildcards.
  def self.load(*path)
    full_path = [ File.dirname(__FILE__), 'nanoc' ] + path
    Dir[File.join(full_path)].each { |f| require f }
  end

end

# Load requirements
begin ; require 'rubygems' ; rescue LoadError ; end
require 'yaml'
require 'fileutils'

# Load base
Nanoc.load('base', 'enhancements.rb')
Nanoc.load('base', 'defaults.rb')
Nanoc.load('base', 'proxy.rb')
Nanoc.load('base', 'proxies', '*.rb')
Nanoc.load('base', 'core_ext', '*.rb')
Nanoc.load('base', 'plugin.rb')
Nanoc.load('base', '*.rb')

# Load extra's
Nanoc.load('extra', 'core_ext', '*.rb')
Nanoc.load('extra', '*.rb')
Nanoc.load('extra', 'vcses', '*.rb')

# Load plugins
Nanoc.load('data_sources', '*.rb')
Nanoc.load('filters', '*.rb')
Nanoc.load('binary_filters', '*.rb')
Nanoc.load('routers', '*.rb')
Nanoc.load('extensions', '*.rb')
