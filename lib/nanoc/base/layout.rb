module Nanoc
  class Layout

    # Default values for layouts.
    PAGE_DEFAULTS = {
      :filter => 'erb'
    }

    attr_reader   :content, :attributes, :path
    attr_accessor :site

    # Creates a new layout.
    def initialize(content, attributes, path)
      @content    = content
      @attributes = attributes
      @path       = path.cleaned_path
    end

    # Returns a proxy for this layout.
    def to_proxy
      @proxy ||= LayoutProxy.new(self)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return PAGE_DEFAULTS[name]
    end

    # Returns the filter class needed for this layout.
    def filter_class
      if attribute_named(:extension).nil?
        PluginManager.instance.filter(attribute_named(:filter).to_sym)
      else
        PluginManager.instance.layout_processor(attribute_named(:extension))
      end
    end

  end
end
