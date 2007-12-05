module Nanoc
  class Compiler

    attr_reader :stack

    def initialize(site)
      @site = site
    end

    def run(page=nil)
      # Require all Ruby source files in lib/
      eval(@site.code, $nanoc_binding)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Reinit
      @stack = []

      # Get pages
      pages = page.nil? ? @site.pages : [ page ]

      # Give feedback
      puts "Compiling #{page.nil? ? 'site' : 'page'}..." unless $quiet
      time_before = Time.now

      # Compile pages
      pages.each do |p|
        p.compile
        p.write unless p.skip_output?
      end

      # Give feedback
      puts "#{page.nil? ? 'Site' : 'Page'} compiled in #{format('%.2f', Time.now - time_before)}s." unless $quiet
    end

  end
end
