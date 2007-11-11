module Nanoc
  class Page

    PAGE_DEFAULTS = {
      :content      => nil,
      :custom_path  => nil,
      :extension    => 'html',
      :file         => nil,
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
    end

    # Proxy support

    def to_proxy(params={})
      PageProxy.new(self, :filter => params[:filter])
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

    # Helper methods

    def content
      filter!
      attribute_named(:content)
    end

    def skip_output?
      attribute_named(:skip_output)
    end

    def path
      attribute_named(:path)
    end

    def filters_pre
      attribute_named(:filters_pre, :filters)
    end

    def filters_post
      attribute_named(:filters_post)
    end

    def layout
      attribute_named(:layout)
    end

    def path_on_filesystem
      if attribute_named(:custom_path).nil?
        @site.config[:output_dir] + attribute_named(:path) +
          attribute_named(:filename) + '.' + attribute_named(:extension)
      else
        @site.config[:output_dir] + attribute_named(:custom_path)
      end
    end

    # Filtering

    def filter!
      # Get stack
      stack = @compiler.stack

      # Check for recursive call
      if stack.include?(self)
        # Print stack
        unless $quiet
          $stderr.puts 'ERROR: Recursive call to page content.'

          # Determine relevant part of stack
          stack_begin = @compiler.stack.index(self)
          stack_end   = @compiler.stack.size
          relevant_stack_part = @compiler.stack.last(stack_end - stack_begin)

          # Print relevant part of stack
          $stderr.puts 'Page filter stack:'
          relevant_stack_part.each_with_index do |page, i|
            $stderr.puts "#{i}  #{page.attribute_named(:path)}"
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
        stack.pushing(self) do
          # Read page
          content = attribute_named(:content) || attribute_named(:uncompiled_content)

          # Get params
          page   = self.to_proxy(:filter => false)
          pages  = @site.pages.map { |p| p.to_proxy }
          config = @site.config

          # Filter page
          @attributes[:content] = content
          filters.each do |filter_name|
            # Create filter
            filter_klass = $nanoc_extras_manager.filter_named(filter_name)
            filter = filter_klass.new(page, pages, config)

            # Run filter
            @attributes[:content] = filter.run(content)
            @is_filtered = true
          end
        end
      end
    end

    def layout!
      # Don't layout if not necessary
      return if attribute_named(:layout).nil?

      # Find layout
      layout = @site.layouts.find { |layout| layout[:name] == attribute_named(:layout) }
      if layout.nil?
        $stderr.puts 'ERROR: Unknown layout: ' + attribute_named(:layout) unless $quiet
        exit(1)
      end

      # Find layout processor
      layout_processor = $nanoc_extras_manager.layout_processor_for_extension(layout[:extension])
      if layout_processor.nil?
        $stderr.puts 'ERROR: Unknown layout processor: ' + layout[:extension] unless $quiet
        exit(1)
      end

      # Get some useful stuff
      page   = self.to_proxy(:filter => false)
      pages  = @site.pages.map { |p| p.to_proxy }
      config = @site.config

      # Layout
      @attributes[:content] = layout_processor.call(page, pages, layout[:content], config)
    end

  end
end
