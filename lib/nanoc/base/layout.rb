module Nanoc

  # A Nanoc::Layout represents a layout in a nanoc site. It has content,
  # attributes (for determining which filter to use for laying out a page), a
  # path (because layouts are organised hierarchically), and a modification
  # time (to speed up compilation).
  class Layout

    # Default values for layouts.
    DEFAULTS = {
      :filter => 'erb'
    }

    # The Nanoc::Site this layout belongs to.
    attr_accessor :site

    # The raw content of this layout.
    attr_reader :content

    # A hash containing this layout's attributes.
    attr_reader :attributes

    # This layout's path, starting and ending with a slash.
    attr_reader :path

    # The time when this layout was last modified.
    attr_reader :mtime

    # Creates a new layout.
    #
    # +content+:: The raw content of this layout.
    #
    # +attributes+:: A hash containing this layout's attributes.
    #
    # +path+:: This layout's path, starting and ending with a slash.
    #
    # +mtime+:: The time when this layout was last modified.
    def initialize(content, attributes, path, mtime=nil)
      @content    = content
      @attributes = attributes.clean
      @path       = path.cleaned_path
      @mtime      = mtime
    end

    # Returns a proxy (Nanoc::LayoutProxy) for this layout.
    def to_proxy
      @proxy ||= LayoutProxy.new(self)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return DEFAULTS[name]
    end

    # Returns the filter class needed for this layout.
    def filter_class
      Nanoc::Filter.named(attribute_named(:filter))
    end

    # Saves the layout in the database, creating it if it doesn't exist yet or
    # updating it if it already exists. Tells the site's data source to save
    # the layout.
    def save
      @site.data_source.loading do
        @site.data_source.save_layout(self)
      end
    end

    # Moves the layout to a new path. Tells the site's data source to move the
    # layout.
    def move_to(new_path)
      @site.data_source.loading do
        @site.data_source.move_layout(self, new_path)
      end
    end

    # Deletes the layout. Tells the site's data source to delete the layout.
    def delete
      @site.data_source.loading do
        @site.data_source.delete_layout(self)
      end
    end

  end

end
