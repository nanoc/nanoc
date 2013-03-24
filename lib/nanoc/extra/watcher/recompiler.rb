# encoding: utf-8

module Nanoc::Extra

  class Watcher

    class Recompiler

      def initialize(watcher_config)
        @watcher_config = watcher_config
      end

      def recompile
        begin
          site = Nanoc::Site.new('.')
          site.compile
          self.notify_success if self.should_notify_success?
        rescue Exception => e
          self.notify_failure if self.should_notify_failure?
          puts
          Nanoc::CLI::ErrorHandler.print_error(e)
        end
      end

      def should_notify_success?
        @_should_notify_success ||= @watcher_config.fetch(:notify_on_compilation_success, true)
      end

      def should_notify_failure?
        @_should_notify_failure ||= @watcher_config.fetch(:notify_on_compilation_failure, true)
      end

      def notify_success
        self.notify('Compilation complete')
      end

      def notify_failure
        self.notify('Compilation failed')
      end

      def notify(message)
        @_notifier ||= Nanoc::Extra::UserNotifier.new
        @_notifier.notify(message)
      end

    end

  end

end
