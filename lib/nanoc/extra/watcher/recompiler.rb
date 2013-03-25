# encoding: utf-8

class Nanoc::Extra::Watcher

  class Recompiler

    NOTIFICATION_MESSAGE_SUCCESS = 'Compilation complete'
    NOTIFICATION_MESSAGE_FAILURE = 'Compilation failed'

    attr_accessor :user_notifier

    # TODO document
    def initialize(params={})
      @watcher_config = params.fetch(:watcher_config)
      @user_notifier  = params.fetch(:user_notifier) { Nanoc::Extra::UserNotifier.new }
    end

    # TODO document
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

    # TODO document
    def should_notify_success?
      @_should_notify_success ||= @watcher_config.fetch(:notify_on_compilation_success, true)
    end

    # TODO document
    def should_notify_failure?
      @_should_notify_failure ||= @watcher_config.fetch(:notify_on_compilation_failure, true)
    end

    # TODO document
    def notify_success
      self.notify(NOTIFICATION_MESSAGE_SUCCESS)
    end

    # TODO document
    def notify_failure
      self.notify(NOTIFICATION_MESSAGE_FAILURE)
    end

    # TODO document
    def notify(message)
      self.user_notifier.notify(message)
    end

  end

end
