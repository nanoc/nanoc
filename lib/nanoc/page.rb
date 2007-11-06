module Nanoc
  class Page

    FILE_TYPES = {
      '.erb'    => :eruby,
      '.rhtml'  => :eruby,
      '.haml'   => :haml,
      '.mab'    => :markaby
    }

    BUILTIN_KEYS = [
      :content,
      :custom_path,
      :extension,
      :file,
      :filename,
      :filters,
      :filters_post,
      :filters_pre,
      :haml_options,
      :is_draft,
      :layout,
      :path,
      :skip_output
    ]

    PAGE_DEFAULTS = {
      :custom_path  => nil,
      :filename     => 'index',
      :extension    => 'html',
      :filters      => [],
      :is_draft     => false,
      :layout       => 'default'
    }

    attr_accessor :stage, :is_filtered

    def initialize(hash, compiler, extra_hash)
      @compiler             = compiler
      @stage                = nil
      @attributes           = hash
      @file                 = nil
      @attributes[:builtin] = (@attributes[:builtin] || {}).merge(extra_hash)
    end

    # Proxy support

    def to_proxy(params={})
      PageProxy.new(self, :filter => params[:filter])
    end

    # Attributes

    def attributes
      @attributes
    end

    def custom_attribute_named(name)
      if @attributes.has_key?(name)
        @attributes[name]
      elsif @compiler.default_attributes.has_key?(name)
        @compiler.default_attributes[name]
      else
        nil
      end
    end

    def builtin_attribute_named(name)
      if @attributes[:builtin].has_key?(name)
        @attributes[:builtin][name]
      elsif @attributes.has_key?(name)
        @attributes[name]
      elsif @compiler.default_attributes.has_key?(name)
        @compiler.default_attributes[name]
      else
        PAGE_DEFAULTS[name]
      end
    end

    # Helper methods

    def content
      filter!
      builtin_attribute_named(:content)
    end

    def file
      builtin_attribute_named(:file)
    end

    def skip_output?
      builtin_attribute_named(:skip_output)
    end

    def is_draft?
      builtin_attribute_named(:is_draft)
    end

    def layout
      builtin_attribute_named(:layout)
    end

    def path_on_filesystem
      if builtin_attribute_named(:custom_path).nil?
        @compiler.config[:output_dir] + builtin_attribute_named(:path) +
          builtin_attribute_named(:filename) + '.' + builtin_attribute_named(:extension)
      else
        @compiler.config[:output_dir] + builtin_attribute_named(:custom_path)
      end
    end

    def find_layout
      if builtin_attribute_named(:layout).nil?
        { :type => :eruby, :content => "<%= @page.content %>" }
      else
        # Find all layouts
        filenames = Dir["layouts/#{builtin_attribute_named(:layout)}.*"]

        # Reject backups
        filenames.reject! { |f| f =~ /~$/ }

        # Make sure there is only one content file
        filenames.ensure_single('layout files', builtin_attribute_named(:layout))

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
        # FIXME this will likely not work if filters are explicitly set to nil
        filters   = attributes[:builtin][:filters_pre] || attributes[:builtin][:filters]
        filters ||= attributes[:filters_pre] || attributes[:filters]
        filters ||= @compiler.default_attributes[:builtin][:filters_pre] || @compiler.default_attributes[:builtin][:filters]
        filters ||= @compiler.default_attributes[:filters_pre] || @compiler.default_attributes[:filters]
        filters ||= []
      elsif @stage == :post
        filters = builtin_attribute_named(:filters_post) || []
      end

      # Filter if not yet filtered
      unless @is_filtered
        stack.pushing(self) do
          # Read page
          content = builtin_attribute_named(:content) || builtin_attribute_named(:uncompiled_content)

          begin
            # Get params
            page   = self.to_proxy(:filter => false)
            pages  = other_pages.map { |p| p.to_proxy }
            config = $nanoc_compiler.config

            # Filter page
            @attributes[:builtin][:content] = content
            filters.each do |filter_name|
              filter = $nanoc_compiler.filter_named(filter_name)
              if filter.nil?
                $delayed_errors << 'WARNING: Unknown filter: ' + filter_name unless $quiet
              else
                @attributes[:builtin][:content] = filter.call(page, pages, config)
                @is_filtered = true
              end
            end
          rescue Exception => exception
            handle_exception(exception, "filter page '#{builtin_attribute_named(:path)}'")
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
      params[:haml_options] = (builtin_attribute_named(:haml_options) || {}).symbolize_keys

      # Layout
      case layout[:type]
      when :eruby
        @attributes[:builtin][:content] = layout[:content].eruby(params)
      when :haml
        @attributes[:builtin][:content] = layout[:content].haml(params)
      when :markaby
        @attributes[:builtin][:content] = layout[:content].markaby(params)
      else
        @attributes[:builtin][:content] = nil
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
        $stderr.puts "#{i}  #{page.builtin_attribute_named(:path)}"
      end
    end

  end
end
