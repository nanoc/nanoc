module Nanoc
  class PluginManager

    @@data_sources       = {}
    @@filters            = {}
    @@layout_processors  = {}

    # Data sources

    def self.data_source_named(name)
      if @@data_sources[name.to_sym].nil?
        objs = []
        ObjectSpace.each_object(Class) do |klass|
          objs << klass if klass < DataSource and klass.identifiers.include?(name.to_sym)
        end
        @@data_sources[name.to_sym] = objs.first
      end

      @@data_sources[name.to_sym]
    end

    # Filters

    def self.filter_named(name)
      if @@filters[name].nil?
        objs = []
        ObjectSpace.each_object(Class) do |klass|
          objs << klass if klass < Filter and klass.identifiers.include?(name.to_sym)
        end
        @@filters[name.to_sym] = objs.first
      end

      @@filters[name.to_sym]
    end

    # Layout processors

    def self.layout_processor_for_extension(ext)
      if @@layout_processors[ext.to_sym].nil?
        objs = []
        ObjectSpace.each_object(Class) do |klass|
          objs << klass if klass < LayoutProcessor and klass.extensions.include?(ext)
        end
        @@layout_processors[ext.to_sym] = objs.first
      end

      @@layout_processors[ext.to_sym]
    end

  end
end
