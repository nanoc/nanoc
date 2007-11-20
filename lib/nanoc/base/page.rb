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

    attr_accessor :stage, :is_filtered

    def initialize(hash, site)
      @site       = site
      @compiler   = site.compiler
      @stage      = nil
      @attributes = hash
      @content    = nil
    end

    # Proxy support

    def to_proxy
      PageProxy.new(self)
    end

    # Attributes

    def attributes
      @attributes
    end

    def attribute_named(*names)
      # Try page attributes first
      names.each do |name|
        return @attributes[name] if @attributes.has_key?(name)
      end

      # Fall back to page defaults
      names.each do |name|
        return @site.page_defaults[name] if @site.page_defaults.has_key?(name)
      end

      # Fall back to compiler page defaults as a last resort
      return PAGE_DEFAULTS[names.first]
    end

    # Accessors

    def content
      filter
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

    # Filtering

    def filter
      # Check for recursive call
      if @compiler.stack.include?(self)
        # Print error
        unless $quiet
          $stderr.puts "\n" + 'ERROR: Recursive call to page content.'
          $stderr.puts 'Page filter stack:'
          @compiler.stack.each_with_index do |page, i|
            $stderr.puts "  #{format('%3s', i.to_s + '.')} #{page.attribute_named(:path)}"
          end
        end

        exit(1)
      end

      # Get filters
      if @stage == :pre
        filters = attribute_named(:filters_pre, :filters)
      else
        filters = attribute_named(:filters_post)
      end

      # Filter if not yet filtered
      unless @is_filtered
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
            @is_filtered = true
          end
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

  end
end
