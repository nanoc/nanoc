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

    def start
      puts 'Listening for changes...'
      @watcher.start
      @watcher.join
    end

    def updated(*events)
      @site.load_data(:force => true)
      events.each do |event|
        page = @site.pages.find { |page| page.attributes[:file].path == event.path }
        @site.compiler.run(page)

        puts
      end
    end

  end
end
