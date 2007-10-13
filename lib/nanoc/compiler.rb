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
      @pages = find_uncompiled_pages

      # Filter, layout, and filter again
      filter(:pre)
      layout
      filter(:post)

      # Save pages
      save_pages
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

        # Convert to a Page instance
        page = Page.new(hash, self)

        # Get the content filename
        page.content_filename = content_filename_for_meta_filename(filename)

        # Skip drafts
        hash[:is_draft] ? pages : pages + [ page ]
      end
    end

    def filter(stage)
      # Reset filter stack
      @stack = []

      # Filter every page
      @pages.each do |page|
        page.stage        = stage
        page.is_filtered  = false
        page.filter!
      end
    end

    def layout
      # For each page (ignoring drafts)
      @pages.reject { |page| page.attributes[:skip_output] }.each do |page|
        begin
          # Layout the page
          page.layout!
        rescue => exception
          handle_exception(exception, "layouting page '#{page.content_filename}' in layout '#{page.attributes[:layout]}'")
        end
      end
    end

    def save_pages
      @pages.reject { |page| page.attributes[:skip_output] }.each do |page|
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

  end
end
