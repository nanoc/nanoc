# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class FileActionPrinter < Abstract
    def initialize(reps:)
      @reps = reps

      @stopwatches = {}
    end

    # @see Listener#start
    def start
      on(:compilation_started) do |rep|
        @stopwatches[rep] ||= DDMetrics::Stopwatch.new
        @stopwatches[rep].start
      end

      on(:compilation_suspended) do |rep|
        @stopwatches[rep].stop
      end

      cached_reps = Set.new
      on(:cached_content_used) do |rep|
        cached_reps << rep
      end

      on(:rep_write_ended) do |rep, _binary, path, is_created, is_modified|
        stopwatch = @stopwatches[rep]
        stopwatch.stop unless stopwatch.stopped?
        # NOTE: stopwatch might have been stopped already, for another snapshot
        # of this rep.

        action =
          if is_created then :create
          elsif is_modified then :update
          elsif cached_reps.include?(rep) then :cached
          else :identical
          end
        level =
          if is_created then :high
          elsif is_modified then :high
          else :low
          end

        # FIXME: do not depend on working directory
        if path.start_with?(Dir.getwd)
          path = path[(Dir.getwd.size + 1)..path.size]
        end

        log(level, action, path, stopwatch.duration)
      end
    end

    # @see Listener#stop
    def stop
      @reps.reject(&:compiled?).each do |rep|
        raw_paths = rep.raw_paths.values.flatten.uniq
        raw_paths.each do |raw_path|
          log(:low, :skip, raw_path, nil)
        end
      end
    end

    private

    def log(level, action, path, duration)
      Nanoc::CLI::Logger.instance.file(level, action, path, duration)
    end
  end
end
