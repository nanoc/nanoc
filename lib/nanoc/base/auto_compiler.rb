module Nanoc
  class AutoCompiler

    def initialize(site)
      # Get site
      @site = site

      # Stop on SIGINT
      Signal.trap('INT') { stop }

      # Load specific stuff
      setup
    end

    def draw_separator
      puts
      puts '-' * 80
      puts
    end

    def start
      puts 'Listening for changes...'
      run
    end

    def update(pages)
      # Map pages to paths
      paths = pages.map { |p| p.attributes[:path] }

      # Reload site data
      @site.load_data(:force => true)

      # Map paths to pages
      real_pages = paths.map { |path| @site.pages.find { |page| page.attributes[:path] == path } }

      # Compile page
      begin ; @site.compiler.run(real_pages) rescue SystemExit ; end

      draw_separator
      puts 'Listening for changes...'
    end

    # Overridden methods

    def setup ; error 'AutoCompiler#setup must be overridden' ; end
    def run   ; error 'AutoCompiler#run must be overridden'   ; end
    def stop  ; error 'AutoCompiler#stop must be overridden'  ; end

  end
end
