module Nanoc
  class PluginManager

    @@data_sources       = {}
    @@filters            = {}
    @@layout_processors  = {}

    def self.subclasses_of(superclass)
      subclasses = []
      ObjectSpace.each_object(Class) { |subclass| subclasses << subclass if subclass < superclass }
      subclasses
    end

    def self.data_source_named(name)
      @@data_sources[name.to_sym] ||= subclasses_of(DataSource).find do |klass|
        klass.identifiers.include?(name.to_sym)
      end
    end

    def self.filter_named(name)
      @@filters[name.to_sym] ||= subclasses_of(Filter).find do |klass|
        klass.identifiers.include?(name.to_sym)
      end
    end

    def self.layout_processor_for_extension(ext)
      @@filters[ext.to_sym] ||= subclasses_of(LayoutProcessor).find do |klass|
        klass.extensions.include?(ext)
      end
    end

  end
end
