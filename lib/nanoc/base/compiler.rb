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

      # Make sure we have the requirements we need
      load_requirements

      # Filter, layout, and filter again
      filter(:pre)
      layout
      filter(:post)

      # Save pages
      write_pages
    end

  private

    # Main methods

    def load_requirements
      # TODO do something like this for layout processors

      # Initialize
      missing_libraries = []
      missing_filters   = []

      # For each page
      @site.pages.each do |page|
        # Check filters
        (page.filters_pre + page.filters_post).each do |filter|
          filter_klass = $nanoc_extras_manager.filter_named(filter)
          # Check whether filter exists
          if filter_klass.nil?
            missing_filters << filter.to_sym
          else
            # Check whether filter requirements exist
            filter_klass.requirements.each do |req|
              begin
                require req
              rescue LoadError
                missing_libraries << req
              end
            end
          end
        end

        # Get rid of duplicates
        missing_libraries.uniq!
        missing_filters.uniq!
      end

      # Print missing filters, if any
      unless missing_filters.empty?
        $stderr.puts 'ERROR: This site requires the following filters to be installed:' unless $quiet 
        missing_filters.each { |filter| $stderr.puts "  - #{filter}" unless $quiet }
        exit(1) if missing_libraries.empty?
      end

      # Print missing libraries, if any
      unless missing_libraries.empty?
        $stderr.puts 'ERROR: This site requires the following Ruby libraries to be installed:' unless $quiet 
        missing_libraries.each { |lib| $stderr.puts "  - #{lib}" unless $quiet }
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
