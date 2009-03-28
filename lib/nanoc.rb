module Nanoc

  # The current nanoc version.
  VERSION = '2.1.6'

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

  module Helpers # :nodoc:
  end

  module Extra # :nodoc:
  end

  module Filters # :nodoc:
  end

  module Routers # :nodoc:
  end

end

# Load requirements
require 'yaml'
require 'fileutils'

# Load nanoc
require 'nanoc/base'
require 'nanoc/extra'
require 'nanoc/data_sources'
require 'nanoc/binary_filters'
require 'nanoc/filters'
require 'nanoc/routers'
require 'nanoc/helpers'
