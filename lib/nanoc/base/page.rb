module Nanoc

  # A Nanoc::Page represents a page in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation. Each page has a list of page representations or reps
  # (Nanoc::PageRep); compiling a page actually compiles all of it's
  # representations..
  class Page

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

    # The Nanoc::Site this page belongs to.
    attr_accessor :site

    # The parent page of this page. This can be nil even for non-root pages.
    attr_accessor :parent

    # The child pages of this page.
    attr_accessor :children

    # This page's raw, uncompiled content.
    attr_reader   :content

    # A hash containing this page's attributes.
    attr_accessor :attributes

    # This page's path.
    attr_reader   :path

    # The time when this page was last modified.
    attr_reader   :mtime

    # This page's list of page representations.
    attr_reader   :reps

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

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false
    end

    # TODO document
    def build_reps
      # Get list of rep names
      rep_names_default = (@site.page_defaults.attributes[:reps] || {}).keys
      rep_names_this    = (@attributes[:reps] || {}).keys + [ :default ]
      rep_names         = rep_names_default | rep_names_this

      # Get list of reps
      reps = rep_names.inject({}) do |memo, rep_name|
        rep = (@attributes[:reps] || {})[rep_name]
        is_bad = (@attributes[:reps] || {}).has_key?(rep_name) && rep.nil?
        is_bad ? memo : memo.merge(rep_name => rep || {})
      end

      # Build reps
      @reps = []
      reps.each_pair do |name, attrs|
        @reps << PageRep.new(self, attrs, name)
      end
    end

    # Returns a proxy (Nanoc::PageProxy) for this page.
    def to_proxy
      @proxy ||= PageProxy.new(self)
    end

    # Returns true if the source page is newer than the compiled page, false
    # otherwise. Also returns false if the page modification time isn't known.
    def outdated?
      # Outdated if we don't know
      return true if @mtime.nil?

      # Outdated if a page rep is outdated
      return @reps.any? { |rep| rep.outdated? }
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @site.page_defaults.attributes[name] if @site.page_defaults.attributes.has_key?(name)
      return DEFAULTS[name]
    end

    # Sets the site to which this page belongs. This will also cause the list
    # of page representations to be built.
    def site=(site)
      @site = site

      # FIXME this is not the best place to build the reps...
      build_reps
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

    # Compiles the page.
    #
    # +also_layout+:: When +true+, will layout and post-filter the page, as
    #                 well as write out the compiled page. Otherwise, will
    #                 just pre-filter the page.
    def compile(also_layout=true)
      # Compile all representations
      @reps.each { |r| r.compile(also_layout) }
    end

  end

end
