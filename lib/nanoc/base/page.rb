module Nanoc

  # A Nanoc::Page represents a page in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation.
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

    # A hash containing this page's attributes.
    attr_accessor :attributes

    # This page's path.
    attr_reader   :path

    # The time when this page was last modified.
    attr_reader   :mtime

    # TODO document
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
      @content        = { :raw => content, :pre => content, :post => nil }
      @path           = path.cleaned_path
      @mtime          = mtime

      # Start disconnected
      @parent         = nil
      @children       = []
      @reps           = {}

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false
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
      return @reps.values.any? { |rep| rep.outdated? }
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @site.page_defaults.attributes[name] if @site.page_defaults.attributes.has_key?(name)
      return DEFAULTS[name]
    end

    # Returns the page's content in the given stage (+:raw+, +:pre+, +:post+)
    def content(stage=:pre)
      compile(false) if stage == :pre  and !@filtered_pre
      compile(true)  if stage == :post and !@filtered_post
      @content[stage]
    end

    # TODO document
    def site=(site)
      @site = site

      build_page_reps
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
      @reps.values.each do |rep|
        rep.compile(also_layout)
      end
    end

  private

    # TODO document
    def build_page_reps
      @reps = {}

      # Get unparsed list of reps
      raw_reps_global = @site.page_defaults.attributes[:reps] || {}
      raw_reps_local  = @attributes[:reps] || {}
      raw_reps = raw_reps_global.merge(raw_reps_local)

      # Build default rep
      default_rep_attrs = (raw_reps || {})[:default] || {}
      @reps[:default] = PageRep.new(self, default_rep_attrs, :default)

      # Build other reps
      (raw_reps || {}).each_pair do |name, attrs|
        next if name == :default
        @reps[name] = PageRep.new(self, attrs, name)
      end
    end

  end

end
