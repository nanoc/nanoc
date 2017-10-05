# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class Abstract
    def initialize(*); end

    def self.enable_for?(command_runner, site) # rubocop:disable Lint/UnusedMethodArgument
      true
    end

    # @abstract
    def start
      raise NotImplementedError, "Subclasses of #{self.class} must implement #start"
    end

    # @abstract
    def stop; end

    def run_while
      start
      yield
    ensure
      stop
    end

    def start_safely
      start
      @_started = true
    end

    def stop_safely
      stop if @_started
      @_started = false
    end

    def on(sym)
      # TODO: clean up on stop
      Nanoc::Int::NotificationCenter.on(sym, self) { |*args| yield(*args) }
    end
  end
end
