module Nanoc
  class Compiler

    DEFAULT_CONFIG = {
      :output_dir   => 'output',
      :eruby_engine => 'erb',
      :data_source  => :filesystem
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
      Dir['lib/**/*.rb'].sort.each { |f| require f }

      # Create output directory if necessary
      FileUtils.mkdir_p(@config[:output_dir])

      # Get all pages
      @pages = find_uncompiled_pages

      # Filter, layout, and filter again
      filter(:pre)
      layout
      filter(:post)

      # Save pages
      write_pages
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
      case @config[:data_source]
      when :filesystem
        Dir['content/**/meta.yaml'].inject([]) do |pages, filename|
          # Read the meta file
          hash = YAML.load_file_and_clean(filename)

          # Get extra info
          path                = filename.sub(/^content/, '').sub('meta.yaml', '')
          content_filename    = content_filename_for_dir(File.dirname(filename), 'content files', File.dirname(filename))
          file                = File.new(content_filename)
          extras = { :path => path, :file => file, :uncompiled_content => file.read }

          # Convert to a Page instance
          page = Page.new(hash, self, extras)

          # Skip drafts
          page.is_draft? ? pages : pages + [ page ]
        end
      else
        $stderr.puts "ERROR: Unrecognised datasource: #{@config[:data_source]}"
        exit(1)
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
      $delayed_errors.sort.uniq.each { |error| $stderr.puts error } unless $quiet
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
          handle_exception(exception, "layouting page '#{page.path}' in layout '#{page.layout}'")
        end
      end

      # Give feedback
      print_immediately ' ' * @pages.select { |page| page.skip_output? }.size
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"

      # Print delayed error messages
      $delayed_errors.sort.uniq.each { |error| $stderr.puts error } unless $quiet
    end

    def write_pages
      @pages.reject { |page| page.skip_output? }.each do |page|
        FileManager.create_file(page.path_on_filesystem) { page.content }
      end
    end

  end
end
