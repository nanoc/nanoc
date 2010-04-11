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
        site.load_data
        begin
          site.compiler.run

          # TODO include icon (--image misc/success-icon.png)
          @notifier.notify('Compilation complete')

          puts "done in #{((Time.now - start)*10000).round.to_f / 10}ms"
        rescue Exception => e
          # TODO include icon (--image misc/error-icon.png)
          @notifier.notify('Compilation failed')

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
      watcher = lambda do
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
      TOOLS = %w( growlnotify notify_send )

      # Error that is raised when no notifier can be found.
      class NoNotifierFound < ::StandardError

        def initialize
          super("Could not find a notifier that works on this system. I tried to find #{CrossPlatformNotifier::TOOLS.join(', ')} but found nothing.")
        end

      end

      # Send a notification.
      #
      # @param [String] message The message to include in the notification
      #
      # @option params [Boolean] :raise (true) true if this method should
      #   raise an exception if no notifier can be found, false otherwise
      def notify(message, params={})
        params[:raise] = true if !params.has_key?(:raise)

        if tool.nil?
          if params[:raise]
            raise NoNotifierFound
          else
            return
          end
        end

        send(tool, message, params)
      end

    private

      def tool
        @tool ||= TOOLS.find { |t| !`which #{t}`.empty? }
      end

      def growlnotify(message, params={})
        system('growlnotify', '-m', message)
      end

      def notify_send(message, params={})
        system('notify_send', messsage)
      end

    end

  end

end
