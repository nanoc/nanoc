module Nanoc
  class Compiler

    attr_reader :stack, :config, :pages, :page_defaults

    def initialize(site)
      @site = site
    end

    def run!
      # Require all Ruby source files in lib/
      Dir['lib/**/*.rb'].sort.each { |f| require f }

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Check requirements
      check_requirements

      # Filter, layout, and filter again
      filter(:pre)
      layout
      filter(:post)

      # Save pages
      write_pages
    end

  private

    # Main methods

    def check_requirements
      # Give feedback
      print_immediately 'Analysing requirements        '
      time_before = Time.now

      # Initialize
      missing_filters = []

      # For each page
      @site.pages.each do |page|
        # Give feedback
        print_immediately '.'

        # Check pre-filters
        page.filters_pre.each do |filter|
          missing_filters << filter.to_sym if $nanoc_extras_manager.filter_named(filter).nil?
        end

        # Check post-filters
        page.filters_post.each do |filter|
          missing_filters << filter.to_sym if $nanoc_extras_manager.filter_named(filter).nil?
        end

        # Get rid of duplicates
        missing_filters.uniq!
      end

      # Give feedback
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"

      # Print missing filters, if any
      unless missing_filters.empty?
        $stderr.puts 'ERROR: This site requires the following filters to be installed:' unless $quiet 
        missing_filters.each { |filter| $stderr.puts "  - #{filter}" unless $quiet }
        $stderr.puts 'nanoc 2.0 only comes with the \'erb\' filter, but you can find all plugins that'
        $stderr.puts 'are no longer included in the standard nanoc distribution on the nanoc wiki,'
        $stderr.puts 'at <http://nanoc.stoneship.org/wiki/>.'
        exit(1)
      end
    end

    def filter(stage)
      # Reinit
      @stack = []

      # Prepare pages
      @site.pages.each do |page|
        page.stage        = stage
        page.is_filtered  = false
      end

      # Give feedback
      print_immediately "Filtering pages #{stage == :pre ? '(first pass) ' : '(second pass)'} "
      time_before = Time.now

      # For each page
      @site.pages.each do |page|
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
    end

    def layout
      # Give feedback
      print_immediately 'Layouting pages               '
      time_before = Time.now

      # For each page
      @site.pages.reject { |page| page.skip_output? }.each do |page|
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
      print_immediately ' ' * @site.pages.select { |page| page.skip_output? }.size
      print_immediately " [#{format('%.2f', Time.now - time_before)}s]\n"
    end

    def write_pages
      @site.pages.reject { |page| page.skip_output? }.each do |page|
        FileManager.create_file(page.path_on_filesystem) { page.content }
      end
    end

    # Helper methods

    def print_immediately(text)
      print text unless $quiet
      $stdout.flush
    end

  end
end
