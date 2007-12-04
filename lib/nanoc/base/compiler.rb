module Nanoc
  class Compiler

    attr_reader :stack, :config, :pages, :page_defaults

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
      pages = @site.pages if pages.nil?

      # Give feedback
      puts "Compiling site..." unless $quiet
      time_before = Time.now

      # Compile pages
      pages.each do |page|
        page.compile
        page.write unless page.skip_output?
      end

      # Give feedback
      puts "Site compiled in #{format('%.2f', Time.now - time_before)}s." unless $quiet
    end

  end
end
