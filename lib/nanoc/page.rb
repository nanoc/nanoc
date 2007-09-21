def try_require(s) ; begin ; require s ; rescue LoadError ; end ; end

try_require 'rubygems'
try_require 'liquid'

module Nanoc

  # Page drop

  begin
    class PageDrop < ::Liquid::Drop
      def initialize(page)
        @page = page
      end

      def before_method(name)
        name == 'content' ? @page.content : @page.attributes[name.to_sym]
      end
    end
  rescue NameError
    class PageDrop
      def initialize(*args)
        $stderr.puts 'ERROR: Liquid not installed; cannot use Liquid in layouts.'
        exit
      end
    end
  end

  # Page proxy

  class PageProxy
    def initialize(page, params={})
      @page       = page
      @do_compile = (params[:compile] != false)
    end

    def [](key)
      if key.to_sym == :content and @do_compile
        @page.content
      else
        if key.to_s.starts_with?('_')
          nil
        elsif key.to_s.ends_with?('?')
          @page.attributes[key.to_s[0..-2].to_sym]
        else
          @page.attributes[key]
        end
      end
    end

    def method_missing(method, *args)
      self[method]
    end
  end

  # Page

  class Page

    def initialize(hash={})
      @attributes = hash
    end

    def attributes
      @attributes
    end

    def content
      compile
      @attributes[:content]
    end

    # Proxy/Liquid support

    def to_proxy(params={})
      PageProxy.new(self, :compile => params[:compile])
    end

    def to_liquid
      PageDrop.new(self)
    end

    # Compiling

    def self.compile(pages)
      @@compilation_stack = []
      @@pages = pages

      # Compile all pages
      pages.each { |page| page.compile }
    end

    def compile
      # Check for recursive call
      if @@compilation_stack.include?(self)
        # Print compilation stack
        unless $quiet
          $stderr.puts 'ERROR: Recursive call to page content.'
          print_compilation_stack
        end

        exit
      # Compile if not yet compiled
      elsif @attributes[:content].nil?
        @@compilation_stack.pushing(self) do
          # Read page
          content = File.read(@attributes[:_content_filename])

          begin
            # Get params
            page   = self.to_proxy(:compile => false)
            pages  = @@pages.map { |p| p.to_proxy }
            config = $nanoc_compiler.config

            # Filter page
            @attributes[:content] = content
            @attributes[:filters].each do |filter_name|
              filter = $nanoc_compiler.filter_named(filter_name)
              if filter.nil?
                $stderr.puts 'WARNING: Unknown filter: ' + filter_name unless $quiet
              else
                @attributes[:content] = filter.call(page, pages, config)
              end
            end
          rescue Exception => exception
            handle_exception(exception, "compiling page '#{@attributes[:_content_filename]}'")
          end
        end
      end
    end

    def print_compilation_stack
      # Determine relevant part of compilation stack
      stack_begin = @@compilation_stack.index(self)
      stack_end   = @@compilation_stack.size
      relevant_stack_part = @@compilation_stack.last(stack_end - stack_begin)

      # Print relevant part of compilation stack
      $stderr.puts 'Page compilation stack:'
      relevant_stack_part.each_with_index do |page, i|
        $stderr.puts "#{i}  #{page.attributes[:_content_filename]}"
      end
    end

  end

end
