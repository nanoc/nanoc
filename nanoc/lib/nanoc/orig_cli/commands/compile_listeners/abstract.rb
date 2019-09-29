# frozen_string_literal: true

module Nanoc::OrigCLI::Commands::CompileListeners
  class Abstract
    def initialize(*)
      super()
    end

    def self.enable_for?(command_runner, site) # rubocop:disable Lint/UnusedMethodArgument
      true
    end

    # @abstract
    def start
      raise NotImplementedError, "Subclasses of #{self.class} must implement #start"
    end

    # @abstract
    def stop; end

    def wrapped_start
      @_notification_names = []
      start
    end

    def wrapped_stop
      stop

      Nanoc::Core::NotificationCenter.sync

      @_notification_names.each do |name|
        Nanoc::Core::NotificationCenter.remove(name, self)
      end
    end

    def run_while
      wrapped_start
      yield
    ensure
      wrapped_stop
    end

    def start_safely
      wrapped_start
      @_started = true
    end

    def stop_safely
      wrapped_stop if @_started
      @_started = false
    end

    def on(sym)
      @_notification_names << sym
      Nanoc::Core::NotificationCenter.on(sym, self) { |*args| yield(*args) }
    end
  end
end
