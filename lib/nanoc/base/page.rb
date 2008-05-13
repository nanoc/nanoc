module Nanoc

  # A Page represents a page in a nanoc site. It has content and attributes,
  # as well as a path. It can also store the modification time to speed up
  # compilation.
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

    attr_accessor :parent, :children, :site
    attr_reader   :mtime

    # Creates a new page. +content+ is the actual content of the page.
    # +attributes+ is a hash containing metadata for the page. +path+ is the
    # path of the page relative to the web root. +mtime+ is the time when the
    # page was last modified (optional).
    def initialize(content, attributes, path, mtime=nil)
      # Set primary attributes
      @attributes     = attributes
      @content        = { :pre => content, :post => nil }
      @path           = path.cleaned_path
      @mtime          = mtime

      # Start disconnected
      @parent         = nil
      @children       = []

      # Reset flags
      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false
    end

    # Returns a proxy (PageProxy) for this page.
    def to_proxy
      @proxy ||= PageProxy.new(self)
    end

    # Returns true if the page has been modified during the last compilation
    # session, false otherwise.
    def modified?
      @modified
    end

    # Returns true if the source page is newer than the compiled page, false
    # otherwise. Also returns false if the page modification time isn't known.
    def outdated?
      # Outdated if compiled file doesn't exist
      return true if !File.file?(path_on_filesystem)

      # Outdated if we don't know
      return true if @mtime.nil?

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

    # Returns the page's pre-filtered but not yet laid out content.
    def content
      compile(false) unless @filtered_pre
      @content[:pre]
    end

    # Returns the page's layout.
    def layout
      # Check whether layout is present
      return nil if attribute_named(:layout).nil?

      # Find layout
      @layout ||= @site.layouts.find { |l| l.path == attribute_named(:layout).cleaned_path }
      error 'Unknown layout: ' + attribute_named(:layout) if @layout.nil?

      @layout
    end

    # Returns the page's pre-filtered, laid out and post-filtered content.
    def laid_out_content
      compile(true)
      @content[:post]
    end

    # Returns the page's path relative to the web root.
    def path
      attribute_named(:custom_path) || @path
    end

    # Returns the path to the compiled page on the filesystem.
    def path_on_filesystem
      if attribute_named(:custom_path).nil?
        @site.config[:output_dir] + @path + attribute_named(:filename) + '.' + attribute_named(:extension)
      else
        @site.config[:output_dir] + attribute_named(:custom_path)
      end
    end

    # Returns the modification time of the compiled page if it exists, nil otherwise.
    def compiled_mtime
      compiled_path = path_on_filesystem
      File.exist?(compiled_path) ? File.stat(compiled_path).mtime : nil
    end

    # Compiles the page. Will layout and post-filter the page, unless +full+
    # is false.
    def compile(full=true)
      @modified = false

      # Check for recursive call
      if @site.compiler.stack.include?(self)
        log(:high, "\n" + 'ERROR: Recursive call to page content. Page filter stack:', $stderr)
        log(:high, "  - #{@path}", $stderr)
        @site.compiler.stack.each_with_index do |page, i|
          log(:high, "  - #{page.path}", $stderr)
        end
        exit(1)
      end

      @site.compiler.stack.push(self)

      # Filter pre
      unless @filtered_pre
        filter!(:pre)
        @filtered_pre = true
      end

      # Layout
      if !@laid_out and full
        layout!
        @laid_out = true
      end

      # Filter post
      if !@filtered_post and full
        filter!(:post)
        @filtered_post = true
      end

      # Write
      if !@written and full
        @modified = FileManager.create_file(self.path_on_filesystem) { @content[:post] } unless attribute_named(:skip_output)
        @written = true
      end

      @site.compiler.stack.pop
    end

  private

    def filter!(stage)
      # Get filters
      error 'The `filters` property is no longer supported; please use `filters_pre` instead.' unless attribute_named(:filters).nil?
      filters = attribute_named(stage == :pre ? :filters_pre : :filters_post)

      filters.each do |filter_name|
        # Create filter
        filter_class = PluginManager.instance.filter(filter_name.to_sym)
        error "Unknown filter: '#{filter_name}'" if filter_class.nil?
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
      error "Cannot determine filter for layout '#{layout.path}'" if filter_class.nil?
      filter = filter_class.new(self.to_proxy, @site)

      # Layout
      @content[:post] = filter.run(layout.content)
    end

  end

end
