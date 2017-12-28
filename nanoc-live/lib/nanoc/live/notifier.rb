# frozen_string_literal: true

module Nanoc::Live
  module NotificationAdapters
    ICON_PATH = __dir__ + '/../../../assets/nanoc.png'

    class TerminalNotifier
      def handle(desc, image)
        ::TerminalNotifier.notify(
          desc,
          title: 'Nanoc',
          group: Process.pid,
          remove: Process.pid,
          contentImage: ICON_PATH,
        )
      end
    end

    class Notiffany
      def initialize
        @notifier = ::Notiffany.connect
      end

      def handle(desc, image)
        @notifier.notify(
          desc,
          title: 'Nanoc',
          image: image,
          timeout: 2,
          group: 'nanoc',
          remove: 'nanoc',
          contentImage: ICON_PATH,
        )
      end
    end

    class Null
      def handle(desc, image)
        # …
      end
    end
  end

  class Notifier
    include Singleton

    def initialize
      @notifier = nil
      @start_queue = SizedQueue.new(1)
      @notifications_queue = Queue.new

      Thread.new do
        Thread.current.abort_on_exception = true

        @notifier = find_adapter_class.new
        @start_queue << true
      end

      Thread.new do
        Thread.current.abort_on_exception = true

        @start_queue.pop
        loop do
          notification = @notifications_queue.pop
          case notification
          when :success
            handle('Site compiled! ✅', :success)
          when :error
            handle('Compilation errored! 💥', :error)
          end
        end
      end
    end

    def notify_success
      @notifications_queue << :success
    end

    def notify_error
      @notifications_queue << :error
    end

    private

    def find_adapter_class
      begin
        require 'terminal-notifier'
        return NotificationAdapters::TerminalNotifier
      rescue LoadError
      end

      begin
        require 'notiffany'
        return NotificationAdapters::Notiffany
      rescue LoadError
      end

      return NotificationAdapters::Null
    end

    def handle(desc, image)
      @notifier.handle(desc, image)
    end
  end
end
