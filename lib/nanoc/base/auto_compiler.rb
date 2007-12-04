module Nanoc
  class AutoCompiler

    def initialize(site)
      begin
        require 'directory_watcher'
      rescue LoadError
        error 'The auto-compilation feature requires the "directory_watcher" gem to be installed.'
      end

      # Create watcher
      @watcher = DirectoryWatcher.new('content', :glob => '**/*', :pre_load => true, :interval => 2)
      @watcher.add_observer(self, :updated)
      Signal.trap('INT') { @watcher.stop }

      # Get site
      @site = site
    end

    def draw_separator
      puts
      puts '-' * 80
      puts
      puts 'Listening for changes...'
    end

    def start
      draw_separator

      @watcher.start
      @watcher.join
    end

    def updated(*events)
      important_events = false

      # Reload site data
      @site.load_data(:force => true)

      events.each do |event|
        # Find page object for event
        page = @site.pages.find do |p|
          event.path == p.attributes[:file].path ||
          event.path == p.attributes[:file].path.sub(/\.[^.]+$/, '.yaml') ||
          event.path == p.attributes[:file].path.sub(/\/[^\/]+$/, '/meta.yaml')
        end

        # Forget about non-important events
        important_events = true unless page.nil?

        # Skip documents without pages
        next if page.nil?

        # Compile page
        begin ; @site.compiler.run(page) ; rescue SystemExit ; end
      end

      draw_separator if important_events
    end

  end
end
