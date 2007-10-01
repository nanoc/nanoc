module Nanoc

  class Page

    attr_accessor :stage, :is_filtered

    def initialize(hash={})
      @attributes = hash
      @stage      = nil
    end

    def attributes
      @attributes
    end

    def content
      filter!
      @attributes[:content]
    end

    # Proxy/Liquid support

    def to_proxy(params={})
      PageProxy.new(self, :filter => params[:filter])
    end

    def to_liquid
      nanoc_require 'liquid'
      PageDrop.new(self)
    end

    # Filtering

    def self.filter(pages, stage)
      @@stack = []
      @@pages = pages

      # Filter all pages
      pages.each do |page|
        page.stage        = stage
        page.is_filtered  = false
        page.filter!
      end
    end

    def filter!
      # Check for recursive call
      if @@stack.include?(self)
        # Print stack
        unless $quiet
          $stderr.puts 'ERROR: Recursive call to page content.'
          print_stack
        end

        exit
      end

      # Get filters
      if @stage == :pre
        filters = @attributes[:filters_pre] || @attributes[:filters] || []
      elsif @stage == :post
        filters = @attributes[:filters_post] || []
      end

      # Filter if not yet filtered
      unless @is_filtered
        @@stack.pushing(self) do
          # Read page
          content = @attributes[:content] || File.read(@attributes[:_content_filename])

          begin
            # Get params
            page   = self.to_proxy(:filter => false)
            pages  = @@pages.map { |p| p.to_proxy }
            config = $nanoc_compiler.config

            # Filter page
            @attributes[:content] = content
            filters.each do |filter_name|
              filter = $nanoc_compiler.filter_named(filter_name)
              if filter.nil?
                $stderr.puts 'WARNING: Unknown filter: ' + filter_name unless $quiet
              else
                @attributes[:content] = filter.call(page, pages, config)
                @is_filtered = true
              end
            end
          rescue Exception => exception
            handle_exception(exception, "filter page '#{@attributes[:_content_filename]}'")
          end
        end
      end
    end

    def print_stack
      # Determine relevant part of stack
      stack_begin = @@stack.index(self)
      stack_end   = @@stack.size
      relevant_stack_part = @@stack.last(stack_end - stack_begin)

      # Print relevant part of stack
      $stderr.puts 'Page filter stack:'
      relevant_stack_part.each_with_index do |page, i|
        $stderr.puts "#{i}  #{page.attributes[:_content_filename]}"
      end
    end

  end

end
