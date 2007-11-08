module Nanoc
  class Page

    PAGE_DEFAULTS = {
      :content      => nil,
      :custom_path  => nil,
      :extension    => 'html',
      :file         => nil,
      :filename     => 'index',
      :filters      => [],
      :filters_pre  => [],
      :filters_post => [],
      :haml_options => {},
      :is_draft     => false,
      :layout       => 'default',
      :path         => nil,
      :skip_output  => false
    }

    attr_accessor :stage, :is_filtered

    def initialize(hash, compiler)
      @compiler   = compiler
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

    def attribute_named(name)
      return @attributes[name]                  if @attributes.has_key?(name)
      return @compiler.default_attributes[name] if @compiler.default_attributes.has_key?(name)
      return PAGE_DEFAULTS[name]
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

    def layout
      attribute_named(:layout)
    end

    def path_on_filesystem
      if attribute_named(:custom_path).nil?
        @compiler.config[:output_dir] + attribute_named(:path) +
          attribute_named(:filename) + '.' + attribute_named(:extension)
      else
        @compiler.config[:output_dir] + attribute_named(:custom_path)
      end
    end

    # Filtering

    def filter!
      # Get stack
      stack  = @compiler.stack

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
        filters ||= attributes[:filters_pre] || attributes[:filters]
        filters ||= @compiler.default_attributes[:filters_pre] || @compiler.default_attributes[:filters]
        filters ||= []
      elsif @stage == :post
        filters ||= attributes[:filters_post]
        filters ||= @compiler.default_attributes[:filters_post]
        filters ||= []
      end

      # Filter if not yet filtered
      unless @is_filtered
        stack.pushing(self) do
          # Read page
          content = attribute_named(:content) || attribute_named(:uncompiled_content)

          # Get params
          page   = self.to_proxy(:filter => false)
          pages  = @compiler.pages.map { |p| p.to_proxy }
          config = $nanoc_compiler.config

          # Filter page
          @attributes[:content] = content
          filters.each do |filter_name|
            # Find filter
            filter = $nanoc_compiler.filter_named(filter_name)
            if filter.nil?
              $delayed_errors << 'WARNING: Unknown filter: ' + filter_name unless $quiet
              next
            end

            # Run filter
            @attributes[:content] = filter.call(page, pages, config)
            @is_filtered = true
          end
        end
      end
    end

    def layout!
      # Don't layout if not necessary
      if attribute_named(:layout).nil?
        return
      end

      # Find layout
      filenames = Dir["layouts/#{attribute_named(:layout)}.*"].reject { |f| f =~ /~$/ }
      filenames.ensure_single('layout files', attribute_named(:layout))
      filename  = filenames[0]
      extension = File.extname(filename)
      layout    = File.read(filename)

      # Find layout processor
      layout_processor = $nanoc_compiler.layout_processor_for_extension(extension)
      if layout_processor.nil?
        $delayed_errors << 'WARNING: Unknown layout processor: ' + extension unless $quiet
        return
      end

      # Get some useful stuff
      page   = self.to_proxy(:filter => false)
      pages  = @compiler.pages.map { |p| p.to_proxy }
      config = $nanoc_compiler.config

      # Layout
      @attributes[:content] = layout_processor.call(page, pages, layout, config)
    end

  end
end
