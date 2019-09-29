# frozen_string_literal: true

module Nanoc::OrigCLI::Commands::CompileListeners
  class Aggregate < Abstract
    def initialize(command_runner:, site:, compiler:)
      @site = site
      @compiler = compiler
      @command_runner = command_runner

      @listener_classes = self.class.default_listener_classes
    end

    def start
      setup_listeners
    end

    def stop
      teardown_listeners
    end

    def self.default_listener_classes
      [
        Nanoc::OrigCLI::Commands::CompileListeners::DiffGenerator,
        Nanoc::OrigCLI::Commands::CompileListeners::DebugPrinter,
        Nanoc::OrigCLI::Commands::CompileListeners::TimingRecorder,
        Nanoc::OrigCLI::Commands::CompileListeners::FileActionPrinter,
      ]
    end

    protected

    def setup_listeners
      res = @compiler.run_until_reps_built
      reps = res.fetch(:reps)

      @listeners =
        @listener_classes
        .select { |klass| klass.enable_for?(@command_runner, @site) }
        .map    { |klass| klass.new(reps: reps) }

      @listeners.each(&:start_safely)
    end

    def teardown_listeners
      return unless @listeners

      @listeners.reverse_each(&:stop_safely)
    end
  end
end
