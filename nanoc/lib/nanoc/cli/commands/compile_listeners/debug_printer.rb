# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class DebugPrinter < Abstract
    # @see Listener#enable_for?
    def self.enable_for?(command_runner, _site)
      command_runner.debug?
    end

    COLOR_MAP = {
      'compilation' => "\e[31m",
      'content' => "\e[32m",
      'filtering' => "\e[33m",
      'dependency_tracking' => "\e[34m",
      'phase' => "\e[35m",
      'stage' => "\e[36m",
    }.freeze

    # @see Listener#start
    def start
      on(:compilation_started) do |rep|
        log('compilation', "Started compilation of #{rep}")
      end

      on(:compilation_ended) do |rep|
        log('compilation', "Ended compilation of #{rep}")
        log('compilation', '')
      end

      on(:compilation_interrupted) do |rep, target_rep, snapshot_name|
        log('compilation', "Interrupted compilation of #{rep}: depends on #{target_rep}, snapshot #{snapshot_name}")
      end

      on(:cached_content_used) do |rep|
        log('content', "Used cached compiled content for #{rep} instead of recompiling")
      end

      on(:snapshot_created) do |rep, snapshot_name|
        log('content', "Snapshot #{snapshot_name} created for #{rep}")
      end

      on(:filtering_started) do |rep, filter_name|
        log('filtering', "Started filtering #{rep} with #{filter_name}")
      end

      on(:filtering_ended) do |rep, filter_name|
        log('filtering', "Ended filtering #{rep} with #{filter_name}")
      end

      on(:dependency_created) do |src, dst|
        log('dependency_tracking', "Dependency created from #{src.inspect} onto #{dst.inspect}")
      end

      on(:phase_started) do |phase_name, rep|
        log('phase', "Phase started: #{phase_name} (rep: #{rep})")
      end

      on(:phase_yielded) do |phase_name, rep|
        log('phase', "Phase yielded: #{phase_name} (rep: #{rep})")
      end

      on(:phase_resumed) do |phase_name, rep|
        log('phase', "Phase resumed: #{phase_name} (rep: #{rep})")
      end

      on(:phase_ended) do |phase_name, rep|
        log('phase', "Phase ended: #{phase_name} (rep: #{rep})")
      end

      on(:phase_aborted) do |phase_name, rep|
        log('phase', "Phase aborted: #{phase_name} (rep: #{rep})")
      end

      on(:stage_started) do |stage_name|
        log('stage', "Stage started: #{stage_name}")
      end

      on(:stage_ended) do |stage_name|
        log('stage', "Stage ended: #{stage_name}")
      end

      on(:stage_aborted) do |stage_name|
        log('stage', "Stage aborted: #{stage_name}")
      end
    end

    def log(progname, msg)
      logger.info(progname) { msg }
    end

    def logger
      @_logger ||=
        Logger.new($stdout).tap do |l|
          l.formatter = proc do |_severity, _datetime, progname, msg|
            "*** #{COLOR_MAP[progname]}#{msg}\e[0m\n"
          end
        end
    end
  end
end
