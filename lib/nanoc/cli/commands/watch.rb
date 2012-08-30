# encoding: utf-8

usage       'watch [options]'
summary     'start the watcher'
description <<-EOS
Start the watcher. When a change is detected, the site will be recompiled.
EOS

module Nanoc::CLI::Commands

  class Watch < ::Nanoc::CLI::CommandRunner

    def run
      require 'listen'
      require 'pathname'

      require_site
      watcher_config = self.site.config[:watcher] || {}

      @notifier = Notifier.new

      # Define rebuilder
      rebuilder = lambda do |file_path|
        # Determine filename
        if file_path.nil?
          filename = nil
        else
          filename = ::Pathname.new(file_path).relative_path_from(::Pathname.new(Dir.getwd)).to_s
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
      rebuilder.call(nil)

      # Get directories to watch
      dirs_to_watch  = watcher_config[:dirs_to_watch]  || ['content', 'layouts', 'lib']
      files_to_watch = watcher_config[:files_to_watch] || ['config.yaml', 'Rules', 'rules', 'Rules.rb', 'rules.rb']
      files_to_watch = Regexp.new(files_to_watch.map { |name| "#{Regexp.quote(name)}$"}.join("|"))
      ignore_dir = Regexp.new(Dir.glob("*").map{|dir| dir if File::ftype(dir) == "directory" }.compact.join("|"))

      # Watch
      puts "Watching for changes…"

        callback = Proc.new do |modified, added, removed|
          rebuilder.call(modified[0]) if modified[0]
          rebuilder.call(added[0]) if added[0]
          rebuilder.call(removed[0]) if removed[0]
        end

        listener = Listen::MultiListener.new(*dirs_to_watch).change(&callback)
        listener_root = Listen::MultiListener.new('', :filter => files_to_watch, :ignore => ignore_dir).change(&callback)

        begin
          listener_root.start(false)
          listener.start
        rescue Interrupt
          listener.stop
          listener_root.stop
        end
    end

    # Allows sending user notifications in a cross-platform way.
    class Notifier

      # A list of commandline tool names that can be used to send notifications
      TOOLS = %w( growlnotify notify-send )

      # The tool to use for discovering binaries' locations
      FIND_BINARY_COMMAND = RUBY_PLATFORM =~ /mingw|mswin/ ? "where" : "which"

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
        @tool ||= begin
          require 'terminal-notifier'
          'terminal-notify'
        rescue LoadError
          TOOLS.find { |t| !`#{FIND_BINARY_COMMAND} #{t}`.empty? }
        end
      end

      def terminal_notify(message)
        TerminalNotifier.notify(message, :title => "nanoc")
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
