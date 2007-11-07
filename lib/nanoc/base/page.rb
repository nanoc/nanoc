module Nanoc
  class Page

    FILE_TYPES = {
      '.erb'    => :eruby,
      '.rhtml'  => :eruby,
      '.haml'   => :haml,
      '.mab'    => :markaby
    }

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

    def file
      attribute_named(:file)
    end

    def skip_output?
      attribute_named(:skip_output)
    end

    def is_draft?
      attribute_named(:is_draft)
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

    def find_layout
      if attribute_named(:layout).nil?
        { :type => :nothing, :content => self.content }
      else
        # Find all layouts
        filenames = Dir["layouts/#{attribute_named(:layout)}.*"]

        # Reject backups
        filenames.reject! { |f| f =~ /~$/ }

        # Make sure there is only one content file
        filenames.ensure_single('layout files', attribute_named(:layout))

        # Get the first (and only one)
        filename = filenames[0]

        { :type => FILE_TYPES[File.extname(filename)], :content => File.read(filename) }
      end
    end

    # Filtering

    def filter!
      # Get stack and list of other pages
      stack       = @compiler.stack
      other_pages = @compiler.pages

      # Check for recursive call
      if stack.include?(self)
        # Print stack
        unless $quiet
          $stderr.puts 'ERROR: Recursive call to page content.'
          print_stack
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

          begin
            # Get params
            page   = self.to_proxy(:filter => false)
            pages  = other_pages.map { |p| p.to_proxy }
            config = $nanoc_compiler.config

            # Filter page
            @attributes[:content] = content
            filters.each do |filter_name|
              filter = $nanoc_compiler.filter_named(filter_name)
              if filter.nil?
                $delayed_errors << 'WARNING: Unknown filter: ' + filter_name unless $quiet
              else
                @attributes[:content] = filter.call(page, pages, config)
                @is_filtered = true
              end
            end
          rescue Exception => exception
            handle_exception(exception, "filter page '#{attribute_named(:path)}'")
          end
        end
      end
    end

    def layout!
      # Get list of other pages
      other_pages = @compiler.pages

      # Find layout
      layout = self.find_layout

      # Build params
      params = { :assigns => { :page => self.to_proxy, :pages => other_pages.map { |p| p.to_proxy } } }
      params[:haml_options] = attribute_named(:haml_options).symbolize_keys

      # Layout
      case layout[:type]
      when :nothing
        @attributes[:content] = layout[:content]
      when :eruby
        @attributes[:content] = layout[:content].eruby(params)
      when :haml
        @attributes[:content] = layout[:content].haml(params)
      when :markaby
        @attributes[:content] = layout[:content].markaby(params)
      else
        @attributes[:content] = nil
      end
    end

    def print_stack
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

  end
end
