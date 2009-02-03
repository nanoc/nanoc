module Nanoc

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

end
