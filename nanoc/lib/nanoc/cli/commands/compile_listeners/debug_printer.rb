# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class DebugPrinter < Abstract
    # @see Listener#enable_for?
    def self.enable_for?(command_runner, _site)
      command_runner.debug?
    end

    # @see Listener#start
    def start
      on(:compilation_started) do |rep|
        puts "*** Started compilation of #{rep}"
      end

      on(:compilation_ended) do |rep|
        puts "*** Ended compilation of #{rep}"
        puts
      end

      on(:compilation_suspended) do |rep, target_rep, snapshot_name|
        puts "*** Suspended compilation of #{rep}: depends on #{target_rep}, snapshot #{snapshot_name}"
      end

      on(:cached_content_used) do |rep|
        puts "*** Used cached compiled content for #{rep} instead of recompiling"
      end

      on(:filtering_started) do |rep, filter_name|
        puts "*** Started filtering #{rep} with #{filter_name}"
      end

      on(:filtering_ended) do |rep, filter_name|
        puts "*** Ended filtering #{rep} with #{filter_name}"
      end

      on(:dependency_created) do |src, dst|
        puts "*** Dependency created from #{src.inspect} onto #{dst.inspect}"
      end

      on(:phase_started) do |phase_name, rep|
        puts "*** Phase started: #{phase_name} (rep: #{rep})"
      end

      on(:phase_yielded) do |phase_name, rep|
        puts "*** Phase yielded: #{phase_name} (rep: #{rep})"
      end

      on(:phase_resumed) do |phase_name, rep|
        puts "*** Phase resumed: #{phase_name} (rep: #{rep})"
      end

      on(:phase_ended) do |phase_name, rep|
        puts "*** Phase ended: #{phase_name} (rep: #{rep})"
      end

      on(:phase_aborted) do |phase_name, rep|
        puts "*** Phase aborted: #{phase_name} (rep: #{rep})"
      end
    end
  end
end
