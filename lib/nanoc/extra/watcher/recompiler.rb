# encoding: utf-8

class Nanoc::Extra::Watcher

  class Recompiler

    NOTIFICATION_MESSAGE_SUCCESS = 'Compilation complete'
    NOTIFICATION_MESSAGE_FAILURE = 'Compilation failed'

    attr_accessor :user_notifier

    def initialize(watcher_config, params={})
      @watcher_config = watcher_config
      @user_notifier  = params.fetch(:user_notifier) { Nanoc::Extra::UserNotifier.new }
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
      self.notify(NOTIFICATION_MESSAGE_SUCCESS)
    end

    def notify_failure
      self.notify(NOTIFICATION_MESSAGE_FAILURE)
    end

    def notify(message)
      self.user_notifier.notify(message)
    end

  end

end
