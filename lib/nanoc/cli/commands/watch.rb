# encoding: utf-8

usage       'watch [options]'
summary     'start the watcher'
be_hidden
description <<-EOS
Start the watcher. When a change is detected, the site will be recompiled.
EOS

module Nanoc::CLI::Commands

  class Watch < ::Nanoc::CLI::CommandRunner

    def run
      warn 'WARNING: The `watch` command is deprecated. Please consider using `guard-nanoc` instead (see https://github.com/nanoc/guard-nanoc).'

      require 'listen'
      require 'pathname'

      require_site
      watcher_config = site.config[:watcher] || {}

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
          print 'Watcher started; compiling the entire site… '
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

          time_spent = ((Time.now - start) * 1000.0).round
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
      dirs_to_watch  = watcher_config[:dirs_to_watch]  || %w( content layouts lib )
      files_to_watch = watcher_config[:files_to_watch] || %w( nanoc.yaml config.yaml Rules rules Rules.rb rules.rb )
      files_to_watch = Regexp.new(files_to_watch.map { |name| Regexp.quote(name) + '$' }.join('|'))
      ignore_dir = Regexp.new(Dir.glob('*').map { |dir| dir if File.directory?(dir) }.compact.join('|'))

      # Watch
      puts 'Watching for changes…'

      callback = proc do |modified, added, removed|
        rebuilder.call(modified[0]) if modified[0]
        rebuilder.call(added[0]) if added[0]
        rebuilder.call(removed[0]) if removed[0]
      end

      listener = Listen::Listener.new(*dirs_to_watch).change(&callback)
      listener_root = Listen::Listener.new('.', :filter => files_to_watch, :ignore => ignore_dir).change(&callback)

      begin
        listener_root.start
        listener.start!
      rescue Interrupt
        listener.stop
        listener_root.stop
      end
    end

    # Allows sending user notifications in a cross-platform way.
    class Notifier

      # A list of commandline tool names that can be used to send notifications
      TOOLS = %w( growlnotify notify-send ) unless defined? TOOLS

      # Send a notification. If no notifier is found, no notification will be
      # created.
      #
      # @param [String] message The message to include in the notification
      def notify(message)
        return if tool.nil?
        if tool == 'growlnotify' && self.on_windows?
          growlnotify_windows(message)
        else
          send(tool.tr('-', '_'), message)
        end
      end

    protected

      def have_tool_nix?(tool)
        !`which #{tool}`.empty?
      rescue Errno::ENOENT
        false
      end

      def have_tool_windows?(tool)
        !`where #{tool} 2> nul`.empty?
      rescue Errno::ENOENT
        false
      end

      def have_tool?(tool)
        if self.on_windows?
          self.have_tool_windows?(tool)
        else
          self.have_tool_nix?(tool)
        end
      end

      def tool
        @tool ||= begin
          require 'terminal-notifier'
          'terminal-notify'
        rescue LoadError
          TOOLS.find { |t| have_tool?(t) }
        end
      end

      def terminal_notify(message)
        TerminalNotifier.notify(message, :title => 'nanoc')
      end

      def growlnotify_cmd_for(message)
        [ 'growlnotify', '-m', message ]
      end

      def growlnotify(message)
        system(*growlnotify_cmd_for(message))
      end

      def growlnotify_windows_cmd_for(message)
        [ 'growlnotify', '/t:nanoc', message ]
      end

      def growlnotify_windows(message)
        system(*growlnotify_windows_cmd_for(message))
      end

      def notify_send(message)
        system('notify-send', message)
      end

      def on_windows?
        Nanoc.on_windows?
      end

    end

  end

end

runner Nanoc::CLI::Commands::Watch
