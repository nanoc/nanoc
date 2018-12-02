# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class FileActionPrinter < Abstract
    def initialize(reps:)
      @stopwatches = {}

      @reps = reps
    end

    # @see Listener#start
    def start
      Nanoc::Int::NotificationCenter.on(:compilation_started, self) do |rep|
        @stopwatches[rep] = DDMetrics::Stopwatch.new.tap(&:start)
      end

      Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) do |rep|
        @stopwatches[rep].stop
      end

      Nanoc::Int::NotificationCenter.on(:compilation_resumed, self) do |rep|
        @stopwatches[rep].start
      end

      cached_reps = Set.new
      Nanoc::Int::NotificationCenter.on(:cached_content_used, self) do |rep|
        cached_reps << rep
      end

      Nanoc::Int::NotificationCenter.on(:rep_write_enqueued, self) do |rep|
        @stopwatches[rep].stop
      end

      Nanoc::Int::NotificationCenter.on(:rep_write_started, self) do |rep, _raw_path|
        @stopwatches[rep].start
      end

      Nanoc::Int::NotificationCenter.on(:rep_write_ended, self) do |rep, _binary, path, is_created, is_modified|
        @stopwatches[rep].stop
        duration = @stopwatches[rep].duration

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

        log(level, action, path, duration)
      end
    end

    # @see Listener#stop
    def stop
      super

      Nanoc::Int::NotificationCenter.remove(:compilation_started, self)
      Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
      Nanoc::Int::NotificationCenter.remove(:compilation_resumed, self)
      Nanoc::Int::NotificationCenter.remove(:cached_content_used, self)
      Nanoc::Int::NotificationCenter.remove(:rep_write_enqueued, self)
      Nanoc::Int::NotificationCenter.remove(:rep_write_started, self)
      Nanoc::Int::NotificationCenter.remove(:rep_write_ended, self)

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
