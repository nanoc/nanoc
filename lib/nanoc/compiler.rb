module Nanoc
  class Compiler

    DEFAULT_CONFIG = {
      :output_dir   => 'output',
      :eruby_engine => 'erb'
    }

    attr_reader :config, :stack, :pages, :default_attributes

    def initialize
      @filters = {}
    end

    def run
      # Make sure we're in a nanoc site
      Nanoc.ensure_in_site

      # Load configuration
      @config = DEFAULT_CONFIG.merge(YAML.load_file_and_clean('config.yaml'))
      @default_attributes = { :builtin => {} }.merge(YAML.load_file_and_clean('meta.yaml'))

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
        hash = YAML.load_file_and_clean(filename)

        # Fix the path
        path = filename.sub(/^content/, '').sub('meta.yaml', '')

        # Convert to a Page instance
        page = Page.new(hash, path, self)

        # Get the content filename
        page.content_filename = content_filename_for_meta_filename(filename)

        # Skip drafts
        page.is_draft? ? pages : pages + [ page ]
      end
    end

    def filter(stage)
      # Reset filter stack
      @stack = []

      # Prepare pages
      @pages.each do |page|
        page.stage        = stage
        page.is_filtered  = false
      end

      # Give feedback
      print_immediately "Filtering pages #{stage == :pre ? '(first pass) ' : '(second pass)'} "
      time_before = Time.now

      # Filter pages
      @pages.each do |page|
        # Give feedback
        print_immediately '.'

        # Filter
        page.filter!
      end

      # Give feedback
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"

      # Print delayed error messages
      $delayed_errors.uniq.each { |error| $stderr.puts error } unless $quiet
    end

    def layout
      # Give feedback
      print_immediately 'Layouting pages               '
      time_before = Time.now

      # For each page (ignoring drafts)
      @pages.reject { |page| page.skip_output? }.each do |page|
        # Give feedback
        print_immediately '.'

        # Layout the page
        begin
          page.layout!
        rescue => exception
          handle_exception(exception, "layouting page '#{page.content_filename}' in layout '#{page.layout}'")
        end
      end

      # Give feedback
      print_immediately ' ' * @pages.select { |page| page.skip_output? }.size
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"

      # Print delayed error messages
      $delayed_errors.uniq.each { |error| $stderr.puts error } unless $quiet
    end

    def save_pages
      @pages.reject { |page| page.skip_output? }.each do |page|
        # Write page with layout
        FileManager.create_file(page.path_on_filesystem) { page.content }
      end
    end

    # Helper methods

    def content_filename_for_meta_filename(filename)
      content_filename_for_dir(File.dirname(filename), 'content files', File.dirname(filename))
    end

  end
end
