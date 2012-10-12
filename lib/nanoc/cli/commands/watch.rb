# encoding: utf-8

usage       'watch [options]'
summary     'start the watcher'
description <<-EOS
Start the watcher. When a change is detected, the site will be recompiled.
EOS

module Nanoc::CLI::Commands

  class Watch < ::Nanoc::CLI::CommandRunner

    def run
      require 'fssm'
      require 'pathname'

      require_site
      watcher_config = self.site.config[:watcher] || {}

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
          print "Change detected to #{filename}; recompiling… "
        else
          print "Watcher started; compiling the entire site… "
        end

        # Recompile
        start = Time.now
        site = Nanoc::Site.new('.')
        begin
          site.compile

          # TODO include icon (--image misc/success-icon.png)
          notify_on_compilation_success = watcher_config.fetch(:notify_on_compilation_success) { true }
          if notify_on_compilation_success
            @notifier.notify('Compilation complete')
          end

          time_spent = ((Time.now - start)*1000.0).round
          puts "done in #{format '%is %ims', *(time_spent.divmod(1000))}"
        rescue Exception => e
          # TODO include icon (--image misc/error-icon.png)
          notify_on_compilation_failure = watcher_config.fetch(:notify_on_compilation_failure) { true }
          if notify_on_compilation_failure
            @notifier.notify('Compilation failed')
          end

          puts
          Nanoc::CLI::ErrorHandler.print_error(e)
          puts
        end
      end

      # Rebuild once
      rebuilder.call(nil, nil)

      # Get directories to watch
      dirs_to_watch  = watcher_config[:dirs_to_watch]  || %w( content layouts lib )
      files_to_watch = watcher_config[:files_to_watch] || %w( config.yaml Rules rules Rules.rb rules.rb' )
      files_to_watch.delete_if { |f| !File.file?(f) }

      # Watch
      puts "Watching for changes…"
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
      TOOLS ||= %w( growlnotify notify-send )

      # The tool to use for discovering binaries' locations
      FIND_BINARY_COMMAND ||= RUBY_PLATFORM =~ /mingw|mswin/ ? "where" : "which"

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
        @tool ||= TOOLS.find { |t| !`#{FIND_BINARY_COMMAND} #{t}`.empty? }
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

runner Nanoc::CLI::Commands::Watch
