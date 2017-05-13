# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class StackProfProfiler < Abstract
    PROFILE_FILE = 'tmp/stackprof_profile'

    # @see Listener#enable_for?
    def self.enable_for?(command_runner)
      command_runner.options.fetch(:profile, false)
    end

    # @see Listener#start
    def start
      require 'stackprof'
      StackProf.start(mode: :cpu)
    end

    # @see Listener#stop
    def stop
      StackProf.stop
      StackProf.results(PROFILE_FILE)
    end
  end
end
