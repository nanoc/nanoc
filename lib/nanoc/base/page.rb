module Nanoc

  # A Nanoc::Page represents a page in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation.
  #
  # Each page has a list of page representations or reps (Nanoc::PageRep);
  # compiling a page actually compiles all of its representations.
  class Page < Nanoc::Item

    # Default values for pages.
    DEFAULTS = {
      :custom_path  => nil,
      :extension    => 'html',
      :filename     => 'index',
      :filters_pre  => [],
      :filters_post => [],
      :layout       => 'default',
      :skip_output  => false
    }

    # The parent page of this page. This can be nil even for non-root pages.
    attr_accessor :parent

    # The child pages of this page.
    attr_accessor :children

    # This page's raw, uncompiled content.
    attr_reader   :content

    # Creates a new page.
    #
    # +content+:: This page's unprocessed content.
    #
    # +attributes+:: A hash containing this page's attributes.
    #
    # +path+:: This page's path.
    #
    # +mtime+:: The time when this page was last modified.
    def initialize(content, attributes, path, mtime=nil)
      # Set primary attributes
      @attributes     = attributes.clean
      @content        = content
      @path           = path.cleaned_path
      @mtime          = mtime

      # Start disconnected
      @parent         = nil
      @children       = []
      @reps           = []
    end

    # Builds the individual page representations (Nanoc::PageRep) for this
    # page.
    def build_reps
      super(PageRep, @site.page_defaults)
    end

    # Returns a proxy (Nanoc::PageProxy) for this page.
    def to_proxy
      super(PageProxy)
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      super(name, @site ? @site.page_defaults : nil, Nanoc::Page::DEFAULTS)
    end

    # Saves the page in the database, creating it if it doesn't exist yet or
    # updating it if it already exists. Tells the site's data source to save
    # the page.
    def save
      @site.data_source.loading do
        @site.data_source.save_page(self)
      end
    end

    # Moves the page to a new path. Tells the site's data source to move the
    # page.
    def move_to(new_path)
      @site.data_source.loading do
        @site.data_source.move_page(self, new_path)
      end
    end

    # Deletes the page. Tells the site's data source to delete the page.
    def delete
      @site.data_source.loading do
        @site.data_source.delete_page(self)
      end
    end

  end

end
