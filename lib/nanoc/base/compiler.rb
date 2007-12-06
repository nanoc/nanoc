module Nanoc
  class Compiler

    attr_reader :stack

    def initialize(site)
      @site = site
    end

    def run(pages=nil)
      # Require all Ruby source files in lib/
      eval(@site.code, $nanoc_binding)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Reinit
      @stack = []

      # Get pages
      real_pages = pages.nil? ? @site.pages : pages

      # Give feedback
      puts "Compiling #{pages.nil? ? 'site' : 'pages'}..." unless $quiet
      time_before = Time.now

      # Compile pages
      real_pages.each do |p|
        p.compile
        p.write unless p.skip_output?
      end

      # Give feedback
      puts "#{pages.nil? ? 'Site' : 'Pages'} compiled in #{format('%.2f', Time.now - time_before)}s." unless $quiet
    end

  end
end
