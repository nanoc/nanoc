module Nanoc
  class Compiler

    attr_reader :stack, :config, :pages, :page_defaults

    def initialize(site)
      @site = site
    end

    def run
      # Require all Ruby source files in lib/
      Dir['lib/**/*.rb'].sort.each { |f| require f }

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Filter, layout, and filter again
      filter(:pre)
      layout
      filter(:post)

      # Save pages
      write_pages
    end

  private

    # Main methods

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

      # Filter each page
      @site.pages.each do |page|
        print_immediately '.'
        begin
          page.filter
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

      # Layout each page
      @site.pages.reject { |page| page.skip_output? }.each do |page|
        print_immediately '.'
        begin
          page.layout
        rescue => exception
          handle_exception(exception, "layouting page '#{page.path}' in layout '#{page.layout[:name]}'")
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
