# encoding: utf-8

module Nanoc3::CLI::Commands

  class Watch < Cri::Command

    def name
      'watch'
    end

    def aliases
      [ ]
    end

    def short_desc
      'start the watcher'
    end

    def long_desc
      'Start the watcher. When a change is detected, the site will be ' \
      'recompiled.'
    end

    def usage
      "nanoc3 watch"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      require 'fssm'
      require 'pathname'

      @notifier = Notifier.new

      # Define rebuilder
      rebuilder = lambda do |base, relative|
        # Determine filename
        if base.nil? || relative.nil?
          filename = nil
        else
          filename = ::Pathname.new(File.join([ base, relative ])).relative_path_from(::Pathname.new(Dir.getwd)).to_s
        end

        # Notify
        if filename
          print "Change detected to #{filename}; recompiling… ".make_compatible_with_env
        else
          print "Watcher started; compiling the entire site… ".make_compatible_with_env
        end

        # Recompile
        start = Time.now
        site = Nanoc3::Site.new('.')
        begin
          site.compile

          # TODO include icon (--image misc/success-icon.png)
          notify_on_compilation_success = site.config.has_key?(:notify_on_compilation_success) ?
            site.config[:notify_on_compilation_success] :
            true
          if notify_on_compilation_success
            @notifier.notify('Compilation complete')
          end

          time_spent = ((Time.now - start)*1000.0).round
          puts "done in #{format '%is %ims', *(time_spent.divmod(1000))}"
        rescue Exception => e
          # TODO include icon (--image misc/error-icon.png)
          notify_on_compilation_failure = site.config.has_key?(:notify_on_compilation_failure) ?
            site.config[:notify_on_compilation_failure] :
            true
          if notify_on_compilation_failure
            @notifier.notify('Compilation failed')
          end

          puts
          @base.print_error(e)
          puts
        end
      end

      # Rebuild once
      rebuilder.call(nil, nil)

      # Get directories to watch
      watcher_config = @base.site.config[:watcher] || {}
      dirs_to_watch  = watcher_config[:dirs_to_watch]  || %w( content layouts lib )
      files_to_watch = watcher_config[:files_to_watch] || %w( config.yaml Rules )

      # Watch
      puts "Watching for changes…".make_compatible_with_env
      watcher = lambda do |*args|
        update(&rebuilder)
        delete(&rebuilder)
        create(&rebuilder)
      end
      monitor = FSSM::Monitor.new
      dirs_to_watch.each  { |dir|      monitor.path(dir, '**/*', &watcher) }
      files_to_watch.each { |filename| monitor.file(filename, &watcher)    }
      monitor.run
    end

    # Allows sending user notifications in a cross-platform way.
    class Notifier

      # A list of commandline tool names that can be used to send notifications
      TOOLS = %w( growlnotify notify-send )

      # Send a notification. If no notifier is found, no notification will be
      # created.
      #
      # @param [String] message The message to include in the notification
      def notify(message)
        return if tool.nil?
        send(tool.tr('-', '_'), message)
      end

    private

      def tool
        @tool ||= TOOLS.find { |t| !`which #{t}`.empty? }
      end

      def growlnotify(message)
        system('growlnotify', '-m', message)
      end

      def notify_send(message)
        system('notify-send', message)
      end

    end

  end

end
