module Nanoc
  class ExtrasManager

    def initialize
      @data_sources       = {}
      @filters            = {}
      @layout_processors  = {}
    end

    # Data sources

    def register_data_source(klass)
      @data_sources[klass.name.to_sym] = klass
    end

    def data_source_named(name)
      @data_sources[name.to_sym]
    end

    # Filters

    def register_filter(name, &block)
      @filters[name.to_sym] = block
    end

    def filter_named(name)
      @filters[name.to_sym]
    end

    # Layout processors

    def register_layout_processor(extension, &block)
      @layout_processors[extension.to_s.sub(/^\./, '').to_sym] = block
    end

    def layout_processor_for_extension(extension)
      @layout_processors[extension.to_s.sub(/^\./, '').to_sym]
    end

  end
end

# Global extras manager (there can be only one)

$nanoc_extras_manager = Nanoc::ExtrasManager.new

# Convenience functions for registering extras

def register_filter(*names, &block)
  names.each { |name| $nanoc_extras_manager.register_filter(name, &block) }
end

def register_layout_processor(*extensions, &block)
  extensions.each { |extension| $nanoc_extras_manager.register_layout_processor(extension, &block) }
end

def register_data_source(klass)
  $nanoc_extras_manager.register_data_source(klass)
end
