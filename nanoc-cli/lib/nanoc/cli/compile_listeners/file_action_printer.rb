# frozen_string_literal: true

module Nanoc::CLI::CompileListeners
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

      on(:rep_write_enqueued) do |rep|
        @stopwatches[rep].stop
      end

      on(:rep_write_started) do |rep, _raw_path|
        @stopwatches[rep].start
      end

      on(:rep_write_ended) do |rep, _binary, path, is_created, is_modified|
        @stopwatches[rep].stop
        duration = @stopwatches[rep].duration

        action =
          if is_created
            :create
          elsif is_modified
            :update
          elsif cached_reps.include?(rep)
            :cached
          else
            :identical
          end
        level =
          if is_created
            :high
          elsif is_modified
            :high
          else
            :low
          end

        # Make path relative (to current working directory)
        # FIXME: do not depend on working directory
        if path.start_with?(Dir.getwd)
          path = path[(Dir.getwd.size + 1)..path.size]
        end

        log(level, action, path, duration)
      end

      on(:file_pruned) do |path|
        # Make path relative (to current working directory)
        # FIXME: do not depend on working directory
        if path.start_with?(Dir.getwd)
          path = path[(Dir.getwd.size + 1)..path.size]
        end

        Nanoc::CLI::Logger.instance.file(:high, :delete, path)
      end

      on(:file_listed_for_pruning) do |path|
        # Make path relative (to current working directory)
        # FIXME: do not depend on working directory
        if path.start_with?(Dir.getwd)
          path = path[(Dir.getwd.size + 1)..path.size]
        end

        Nanoc::CLI::Logger.instance.file(:high, :delete, '(dry run) ' + path)
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
