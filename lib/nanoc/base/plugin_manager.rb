require 'singleton'

module Nanoc
  class PluginManager

    include Singleton

    def initialize
      @data_sources       = {}
      @filters            = {}
      @layout_processors  = {}
    end

    def data_source(name)     ; @data_sources[name]     ||= find(DataSource, :identifiers, name)    ; end
    def filter(name)          ; @filters[name]          ||= find(Filter, :identifiers, name)        ; end
    def layout_processor(ext) ; @layout_processors[ext] ||= find(LayoutProcessor, :extensions, ext) ; end

  private

    def find(superclass, attribute, value)
      subclasses = []
      ObjectSpace.each_object(Class) { |subclass| subclasses << subclass if subclass < superclass }
      subclasses.find { |klass| klass.send(attribute).include?(value) }
    end

  end
end
