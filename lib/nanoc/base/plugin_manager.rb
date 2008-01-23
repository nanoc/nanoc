require 'singleton'

module Nanoc

  # Nanoc::PluginManager is a singleton class that is responsible for
  # finding plugins such as data sources, filters and layout processors.
  class PluginManager

    include Singleton

    def initialize # :nodoc:
      @data_sources       = {}
      @filters            = {}
      @layout_processors  = {}
    end

    # Returns the data source class with the given identifier
    def data_source(identifier)
      @data_sources[identifier] ||= find(DataSource, :identifiers, identifier)
    end

    # Returns the filter class with the given identifier
    def filter(identifier)
      @filters[identifier] ||= find(Filter, :identifiers, identifier)
    end

    # Returns the layout processor class with the given file extension
    def layout_processor(ext)
      @layout_processors[ext] ||= find(LayoutProcessor, :extensions, ext)
    end

  private

    def find(superclass, attribute, value)
      subclasses = []
      ObjectSpace.each_object(Class) { |subclass| subclasses << subclass if subclass < superclass }
      subclasses.find { |klass| klass.send(attribute).include?(value) }
    end

  end

end
