module Nanoc
  class Compiler

    DEFAULT_CONFIG = {
      :output_dir   => 'output',
      :eruby_engine => 'erb'
    }

    FILE_TYPES = {
      '.erb'    => :eruby,
      '.rhtml'  => :eruby,
      '.haml'   => :haml,
      '.mab'    => :markaby,
      '.liquid' => :liquid
    }

    PAGE_DEFAULTS = {
      :custom_path  => nil,
      :filename     => 'index',
      :extension    => 'html',
      :filters      => [],
      :is_draft     => false,
      :layout       => 'default'
    }

    attr_reader :config, :stack, :pages

    def initialize
      @filters = {}
    end

    def run
      # Make sure we're in a nanoc site
      Nanoc.ensure_in_site

      # Load some configuration stuff
      @config      = DEFAULT_CONFIG.merge(YAML.load_file_and_clean('config.yaml'))
      @global_page = PAGE_DEFAULTS.merge(YAML.load_file_and_clean('meta.yaml'))

      # Require all Ruby source files in lib/
      Dir['lib/*.rb'].each { |f| require f }

      # Create output directory if necessary
      FileUtils.mkdir_p(@config[:output_dir])

      # Get all pages
      pages = find_uncompiled_pages

      # Filter, layout, and filter again
      filter(pages, :pre)
      layout(pages)
      filter(pages, :post)

      # Save pages
      save_pages(pages)
    end

    # Filter management

    def register_filter(name, &block)
      @filters[name.to_sym] = block
    end

    def filter_named(name)
      @filters[name.to_sym]
    end

  private

    # Main methods

    def find_uncompiled_pages
      # Read all meta files
      Dir['content/**/meta.yaml'].inject([]) do |pages, filename|
        # Read the meta file
        hash = @global_page.merge(YAML.load_file_and_clean(filename))

        # Fix the path
        hash[:path] = filename.sub(/^content/, '').sub('meta.yaml', '')

        # Convert to a P age instance
        page = Page.new(hash, self)

        # Get the content filename
        page.content_filename = content_filename_for_meta_filename(filename)

        # Skip drafts
        if hash[:is_draft]
          pages
        else
          pages + [ page ]
        end
      end
    end

    def filter(pages, stage)
      # Reset filter stack and list of pages
      @stack = []
      @pages = pages

      # Filter every page
      pages.each do |page|
        page.stage        = stage
        page.is_filtered  = false
        page.filter!
      end
    end

    def layout(pages)
      pages.reject { |page| page.attributes[:skip_output] }.each do |page|
        begin
          page.attributes[:content] = layouted_page(page, pages)
        rescue => exception
          p = page.content_filename
          l = page.attributes[:layout]
          handle_exception(exception, "layouting page '#{p}' in layout '#{l}'")
        end
      end

      pages
    end

    def save_pages(pages)
      pages.reject { |page| page.attributes[:skip_output] }.each do |page|
        # Write page with layout
        FileManager.create_file(page.path) { page.content }
      end
    end

    # Helper methods

    def content_filename_for_meta_filename(filename)
      # Find all files with base name of parent directory
      content_filenames = Dir[filename.sub('meta.yaml', File.basename(File.dirname(filename)) + '.*')]

      # Find all index.* files (used to be a fallback for nanoc 1.0, kinda...)
      content_filenames += Dir["#{File.dirname(filename)}/index.*"]

      # Reject backups
      content_filenames.reject! { |f| f =~ /~$/ }

      # Make sure there is only one content file
      content_filenames.ensure_single('content files', File.dirname(filename))

      # Return the first (and only one)
      content_filenames[0]
    end

    def layouted_page(page, pages)
      # Find layout
      layout = page.layout

      # Build params
      if layout[:type] == :liquid
        public_page   = page.to_liquid
        public_pages  = pages.map { |p| p.to_liquid }
      else
        public_page   = page.to_proxy
        public_pages  = pages.map { |p| p.to_proxy }
      end
      params = { :assigns => { :page => public_page, :pages => public_pages } }
      params[:haml_options] = (page.attributes[:haml_options] || {}).symbolize_keys

      # Layout
      case layout[:type]
      when :eruby
        content = layout[:content].eruby(params)
      when :haml
        content = layout[:content].haml(params)
      when :markaby
        content = layout[:content].markaby(params)
      when :liquid
        content = layout[:content].liquid(params)
      else
        content = nil
      end

      content
    end

  end
end
