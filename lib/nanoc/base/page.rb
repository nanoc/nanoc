module Nanoc

  # A Nanoc::Page represents a page in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation.
  class Page

    # Default values for pages.
    PAGE_DEFAULTS = {
      :custom_path  => nil,
      :extension    => 'html',
      :filename     => 'index',
      :filters_pre  => [],
      :filters_post => [],
      :is_draft     => false,
      :layout       => 'default',
      :path         => nil,
      :skip_output  => false
    }

    # The Nanoc::Site this page belongs to.
    attr_accessor :site

    # The parent page of this page. This can be nil even for non-root pages.
    attr_accessor :parent

    # The child pages of this page.
    attr_accessor :children

    # The page's unprocessed content
    attr_accessor :content

    # A hash containing this page's attributes.
    attr_accessor :attributes

    # This page's path.
    attr_accessor :path

    # The time when this page was last modified.
    attr_accessor :mtime

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

    # Returns true if the compiled page has been modified during the last
    # compilation session, false otherwise.
    def modified?
      @modified
    end

    # Returns true if the compiled page did not exist before and had to be
    # recreated, false otherwise.
    def created?
      @created
    end

    # Returns true if the source page is newer than the compiled page, false
    # otherwise. Also returns false if the page modification time isn't known.
    def outdated?
      # Outdated if compiled file doesn't exist
      return true if !File.file?(disk_path)

      # Outdated if we don't know
      return true if @mtime.nil?

      # Calculate compiled mtime
      compiled_mtime = File.exist?(disk_path) ? File.stat(disk_path).mtime : nil

      # Outdated if file too old
      return true if @mtime > compiled_mtime

      # Outdated if dependencies outdated
      return true if @site.layouts.any? { |l| l.mtime > compiled_mtime }
      return true if @site.page_defaults.mtime > compiled_mtime
      return true if @site.code.mtime > compiled_mtime

      return false
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @site.page_defaults.attributes[name] if @site.page_defaults.attributes.has_key?(name)
      return PAGE_DEFAULTS[name]
    end

    # Returns the page's content in the given stage (+:raw+, +:pre+, +:post+)
    def content(stage=:pre)
      compile(false) if stage == :pre  and !@filtered_pre
      compile(true)  if stage == :post and !@filtered_post
      @content[stage]
    end

    # Returns the page's layout.
    def layout
      # Check whether layout is present
      return nil if attribute_named(:layout).nil?

      # Find layout
      @layout ||= @site.layouts.find { |l| l.path == attribute_named(:layout).cleaned_path }
      raise Nanoc::Errors::UnknownLayoutError.new(attribute_named(:layout)) if @layout.nil?

      @layout
    end

    # Returns the path to the compiled page on the disk.
    def disk_path
      @disk_path ||= @site.config[:output_dir] + @site.router.disk_path_for(self)
    end

    # Returns the path to the compiled page as used in the web site itself.
    def web_path
      @web_path ||= @site.router.web_path_for(self)
    end

    # Compiles the page.
    #
    # +also_layout+:: When +true+, will layout and post-filter the page, as
    #                 well as write out the compiled page. Otherwise, will
    #                 just pre-filter the page.
    def compile(also_layout=true)
      @modified = false

      # Check for recursive call
      if @site.compiler.stack.include?(self)
        @site.compiler.stack.push(self)
        raise Nanoc::Errors::RecursiveCompilationError.new 
      end

      @site.compiler.stack.push(self)

      # Filter pre
      unless @filtered_pre
        filter!(:pre)
        @filtered_pre = true
      end

      # Layout
      if !@laid_out and also_layout
        layout!
        @laid_out = true
      end

      # Filter post
      if !@filtered_post and also_layout
        filter!(:post)
        @filtered_post = true
      end

      # Write
      if !@written and also_layout
        # Check status
        @created  = !File.file?(self.disk_path)
        @modified = @created ? true : File.read(self.disk_path) == @content[:post]

        # Write
        unless attribute_named(:skip_output)
          FileUtils.mkdir_p(File.dirname(self.disk_path))
          File.open(self.disk_path, 'w') { |io| io.write(@content[:post]) }
        end

        # Done
        @written = true
      end

      @site.compiler.stack.pop
    end

  private

    def filter!(stage)
      # Get filters
      unless attribute_named(:filters).nil?
        raise Nanoc::Errors::NoLongerSupportedError.new(
          'The `filters` property is no longer supported; please use `filters_pre` instead.'
        )
      end
      filters = attribute_named(stage == :pre ? :filters_pre : :filters_post)

      filters.each do |filter_name|
        # Create filter
        filter_class = PluginManager.instance.filter(filter_name.to_sym)
        raise Nanoc::Errors::UnknownFilterError.new(filter_name) if filter_class.nil?
        filter = filter_class.new(self.to_proxy, @site)

        # Run filter
        @content[stage] = filter.run(@content[stage])
      end
    end

    def layout!
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        @content[:post] = @content[:pre]
        return
      end

      # Find layout processor
      filter_class = layout.filter_class
      raise CannotDetermineFilterError(layout.path) if filter_class.nil?
      filter = filter_class.new(self.to_proxy, @site)

      # Layout
      @content[:post] = filter.run(layout.content)
    end

  end

end
