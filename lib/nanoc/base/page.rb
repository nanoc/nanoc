module Nanoc
  class Page

    PAGE_DEFAULTS = {
      :custom_path  => nil,
      :extension    => 'html',
      :filename     => 'index',
      :filters_pre  => [],
      :filters_post => [],
      :haml_options => {},
      :is_draft     => false,
      :layout       => 'default',
      :path         => nil,
      :skip_output  => false
    }

    attr_accessor :parent, :children

    def initialize(hash, site)
      @site       = site
      @compiler   = site.compiler

      @attributes = hash
      @content    = nil

      @parent     = nil
      @children   = []

      @filtered_pre  = false
      @layouted      = false
      @filtered_post = false
    end

    # Proxy support

    def to_proxy
      @proxy ||= PageProxy.new(self)
    end

    # Attributes

    def attributes
      @attributes
    end

    def attribute_named(name)
      return @attributes[name]         if @attributes.has_key?(name)
      return @site.page_defaults[name] if @site.page_defaults.has_key?(name)
      return PAGE_DEFAULTS[name]
    end

    # Accessors

    def content
      compile
      @content
    end

    def skip_output? ; attribute_named(:skip_output)            ; end
    def path         ; attribute_named(:path)                   ; end
    def filters_pre  ; attribute_named(:filters_pre, :filters)  ; end
    def filters_post ; attribute_named(:filters_post)           ; end

    def path_on_filesystem
      if attribute_named(:custom_path).nil?
        @site.config[:output_dir] + attribute_named(:path) +
          attribute_named(:filename) + '.' + attribute_named(:extension)
      else
        @site.config[:output_dir] + attribute_named(:custom_path)
      end
    end

    # Compiling

    def compile
      unless @filtered_pre
        @filtered_pre = true
        filter(:pre)
      end

      unless @layouted
        @layouted = true
        layout
      end

      unless @filtered_post
        @filtered_post = true
        filter(:post)
      end
    rescue => exception
      unless $quiet or exception.class == SystemExit
        $stderr.puts "ERROR: Exception occured while compiling #{path}:\n"
        $stderr.puts exception
        $stderr.puts exception.backtrace.join("\n")
      end
      exit(1)
    end

    def filter(stage)
      # Check for recursive call
      if @compiler.stack.include?(self)
        # Print error
        unless $quiet
          $stderr.puts "\n" + 'ERROR: Recursive call to page content.'
          $stderr.puts 'Page filter stack:'
          $stderr.puts "  - #{self.attribute_named(:path)}"
          @compiler.stack.each_with_index do |page, i|
            $stderr.puts "  - #{page.attribute_named(:path)}"
          end
        end

        exit(1)
      end

      # Get filters
      error 'The `filters` property is no longer supported; please use `filters_pre` instead.' unless attribute_named(:filters).nil?
      filters = attribute_named(stage == :pre ? :filters_pre : :filters_post)

      @compiler.stack.pushing(self) do
        # Read page
        @content = attribute_named(:uncompiled_content) if @content.nil?

        # Filter page
        filters.each do |filter_name|
          # Create filter
          filter_class = PluginManager.filter_named(filter_name)
          error "Unknown filter: '#{filter_name}'" if filter_class.nil?
          filter = filter_class.new(self.to_proxy, @site.pages.map { |p| p.to_proxy }, @site.config, @site)

          # Run filter
          @content = filter.run(@content)
        end
      end
    end

    def layout
      # Don't layout if not necessary
      return if attribute_named(:layout).nil?

      # Find layout
      layout = @site.layouts.find { |l| l[:name] == attribute_named(:layout) }
      error 'Unknown layout: ' + attribute_named(:layout) if layout.nil?

      # Find layout processor
      layout_processor_class = PluginManager.layout_processor_for_extension(layout[:extension])
      error "Unknown layout processor: '#{layout[:extension]}'" if layout_processor_class.nil?
      layout_processor = layout_processor_class.new(self.to_proxy, @site.pages.map { |p| p.to_proxy }, @site.config, @site)

      # Layout
      @content = layout_processor.run(layout[:content])
    end

    def write
      FileManager.create_file(self.path_on_filesystem) { @content }
    end

  end
end
