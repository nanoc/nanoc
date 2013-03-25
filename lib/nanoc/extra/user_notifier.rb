# encoding: utf-8

module Nanoc::Extra

  # Sends notifications (Mountain Lion notifications, Growl notification, ...)
  #
  # @api private
  class UserNotifier

    # Send a notification. If no notifier is found, no notification will be
    # created.
    #
    # @param [String] message The message to include in the notification
    def notify(message)
      tool = self.find_tool
      return if tool.nil?
      send(tool.tr('-', '_'), message)
    end

    # @return [String] The name of the binary of the preferred tool
    def find_tool
      @tool ||= begin
        require 'terminal-notifier'
        'terminal-notify'
      rescue LoadError
        begin
          self.tools.find { |t| !`#{self.find_binary_command} #{t}`.empty? }
        rescue Errno::ENOENT
          nil
        end
      end
    end

    # @return [String] "where" on Windows, "which" elsewhere
    def find_binary_command
      @find_binary_command ||= (self.on_windows? ? "where" : "which")
    end

    # @return [Boolean] true oon Windows, false elsewhere
    def on_windows?
      if instance_variable_defined?(:@pretend_on_windows)
        @pretend_on_windows
      else
        RUBY_PLATFORM =~ /mingw|mswin/
      end
    end

    # Force the notifier to believe it is on Windows.
    #
    # @return [void]
    def pretend_on_windows
      @pretend_on_windows = true
    end

    # Force the notifier to believe it is not on Windows.
    #
    # @return [void]
    def pretend_not_on_windows
      @pretend_on_windows = false
    end

  protected

    def tools
      %w( growlnotify notify-send )
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
