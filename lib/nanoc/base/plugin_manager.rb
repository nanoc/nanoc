module Nanoc
  class PluginManager

    # Data sources

    def self.data_sources_named(name)
      objs = []
      ObjectSpace.each_object(Class) do |klass|
        objs << klass if klass < Nanoc::DataSource and klass.identifiers.include?(name.to_sym)
      end
      objs
    end

    def self.data_source_named(name) ; self.data_sources_named(name).first ; end

    # Filters

    def self.filters_named(name)
      objs = []
      ObjectSpace.each_object(Class) do |klass|
        objs << klass if klass < Nanoc::Filter and klass.identifiers.include?(name.to_sym)
      end
      objs
    end

    def self.filter_named(name) ; self.filters_named(name).first ; end

    # Layout processors

    def self.layout_processors_for_extension(ext)
      objs = []
      ObjectSpace.each_object(Class) do |klass|
        objs << klass if klass < Nanoc::LayoutProcessor and klass.extensions.include?(ext)
      end
      objs
    end

    def self.layout_processor_for_extension(name) ; self.layout_processors_for_extension(name).first ; end

  end
end
