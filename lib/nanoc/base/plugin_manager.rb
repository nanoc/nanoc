require 'singleton'

module Nanoc

  # Nanoc::PluginManager is a singleton class that is responsible for
  # finding plugins such as data sources, filters and layout processors.
  class PluginManager

    include Singleton

    def initialize # :nodoc:
      @data_sources       = {}
      @filters            = {}
      @binary_filters     = {}
      @layout_processors  = {}
      @routers            = {}
    end

    # Returns the data source (Nanoc::DataSource) class with the given
    # identifier.
    def data_source(identifier)
      @data_sources[identifier] ||= find(DataSource, :identifiers, identifier)
    end

    # Returns the filter (Nanoc::Filter) class with the given identifier.
    def filter(identifier)
      @filters[identifier] ||= find(Filter, :identifiers, identifier)
    end

    # Returns the binary filter (Nanoc::BinaryFilter) class with the given
    # identifier.
    def binary_filter(identifier)
      @binary_filters[identifier] ||= find(BinaryFilter, :identifiers, identifier)
    end

    # Returns the filter (Nanoc::Filter)class, used as layout processor, with
    # the given file extension.
    def layout_processor(ext)
      @layout_processors[ext] ||= find(Filter, :extensions, ext)
    end

    # Returns the router (Nanoc::Router) class with the given identifier.
    def router(identifier)
      @routers[identifier] ||= find(Router, :identifiers, identifier)
    end

    # Returns all subclasses of the given class.
    def find_all(superclass)
      subclasses = []
      ObjectSpace.each_object(Class) { |subclass| subclasses << subclass if subclass < superclass }
      subclasses
    end

    # Returns all subclasses of the given class, where the attribute named
    # +attribute+ is an array containing +value+.
    def find(superclass, attribute, value)
      find_all(superclass).find { |c| c.send(attribute).include?(value) }
    end

  end

end
