module Nanoc
  class Compiler

    DEFAULT_CONFIG = {
      :output_dir   => 'output',
      :eruby_engine => 'erb',
      :datasource   => 'filesystem'
    }

    attr_reader :config, :stack, :pages, :default_attributes

    def initialize
      @filters            = {}
      @layout_processors  = {}
    end

    def prepare
      # Load configuration
      @config = DEFAULT_CONFIG.merge(YAML.load_file_and_clean('config.yaml'))

      # Open database
      if @config[:datasource] == 'database'
        ActiveRecord::Base.establish_connection(config[:database])
      end

      # Load default metadata
      @default_attributes = YAML.load_file_and_clean('meta.yaml')
    end

    def run
      # Make sure we're in a nanoc site
      Nanoc.ensure_in_site

      # Prepare nanoc for usage
      prepare

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

    # Filter and layout processor management

    def register_filter(name, &block)
      @filters[name.to_sym] = block
    end

    def filter_named(name)
      @filters[name.to_sym]
    end

    def register_layout_processor(extension, &block)
      @layout_processors[extension.to_s.sub(/^\./, '').to_sym] = block
    end

    def layout_processor_for_extension(extension)
      @layout_processors[extension.to_s.sub(/^\./, '').to_sym]
    end

  private

    # Main methods

    def find_uncompiled_pages
      # Read all meta files
      case @config[:datasource]
      when 'filesystem'
        Dir['content/**/meta.yaml'].inject([]) do |pages, filename|
          # Read the meta file
          hash = YAML.load_file_and_clean(filename)

          # Get extra info
          path              = filename.sub(/^content/, '').sub('meta.yaml', '')
          content_filename  = content_filename_for_dir(File.dirname(filename), 'content files', File.dirname(filename))
          file              = File.new(content_filename)
          extras            = { :path => path, :file => file, :uncompiled_content => file.read }

          # Convert to a Page instance
          page = Page.new(hash.merge(extras), self)

          # Skip drafts
          hash[:is_draft] ? pages : pages + [ page ]
        end
      when 'database'
        nanoc_require 'active_record'

        # Create Pages for each database object
        DBPage.find(:all).map do |page|
          hash    = (YAML.load(page.meta || '') || {}).clean
          extras  = { :path => page.path, :uncompiled_content => page.content }
          Page.new(hash.merge(extras), self)
        end
      else
        $stderr.puts "ERROR: Unrecognised datasource: #{@config[:datasource]}"
        exit(1)
      end
    end

    def filter(stage)
      # Reinit
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
        begin
          page.filter!
        rescue => exception
          handle_exception(exception, "filtering page '#{page.path}'")
        end
      end

      # Give feedback
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"
      print_delayed_errors
    end

    def layout
      # Give feedback
      print_immediately 'Layouting pages               '
      time_before = Time.now

      # For each page (ignoring drafts)
      @pages.reject { |page| page.skip_output? }.each do |page|
        # Give feedback
        print_immediately '.'

        # Layout
        begin
          page.layout!
        rescue => exception
          handle_exception(exception, "layouting page '#{page.path}' in layout '#{page.layout}'")
        end
      end

      # Give feedback
      print_immediately ' ' * @pages.select { |page| page.skip_output? }.size
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"
      print_delayed_errors
    end

    def write_pages
      @pages.reject { |page| page.skip_output? }.each do |page|
        FileManager.create_file(page.path_on_filesystem) { page.content }
      end
    end

    # Helper functions

    def print_delayed_errors
      $delayed_errors.sort.uniq.each { |error| $stderr.puts error } unless $quiet
      $delayed_errors = []
    end

  end
end
