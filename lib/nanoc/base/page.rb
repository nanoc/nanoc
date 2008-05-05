module Nanoc
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

    attr_reader   :attributes
    attr_accessor :parent, :children, :site

    # Creates a new page.
    def initialize(content, attributes, path)
      @attributes     = attributes
      @content        = { :pre => content, :post => nil }
      @path           = path.cleaned_path

      @parent         = nil
      @children       = []

      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false
    end

    # Returns a proxy for this page.
    def to_proxy
      @proxy ||= PageProxy.new(self)
    end

    # Returns true if the page has been modified during the last compilation
    # session, false otherwise.
    def modified?
      @modified
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name]         if @attributes.has_key?(name)
      return @site.page_defaults[name] if @site.page_defaults.has_key?(name)
      return PAGE_DEFAULTS[name]
    end

    # Returns the page's pre-filtered but not yet laid out content.
    def content
      compile(false) unless @filtered_pre
      @content[:pre]
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
        filter(:pre)
        @filtered_pre = true
      end

      # Layout
      if !@laid_out and full
        layout
        @laid_out = true
      end

      # Filter post
      if !@filtered_post and full
        filter(:post)
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

    def filter(stage)
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

    def layout
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        @content[:post] = @content[:pre]
        return
      end

      # Find layout
      layout = @site.layouts.find do |l|
        (l[:path] || l[:name]).cleaned_path == attribute_named(:layout).cleaned_path
      end
      error 'Unknown layout: ' + attribute_named(:layout) if layout.nil?

      # Find layout processor
      if layout[:extension].nil?
        layout_processor_class = PluginManager.instance.filter(layout[:filter].to_sym)
      else
        layout_processor_class = PluginManager.instance.layout_processor(layout[:extension])
      end
      error "Unknown layout processor: '#{layout[:extension]}'" if layout_processor_class.nil?
      layout_processor = layout_processor_class.new(self.to_proxy, @site)

      # Layout
      @content[:post] = layout_processor.run(layout[:content])
    end

  end
end
