# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class TimingRecorder < Abstract
    attr_reader :telemetry

    # @see Listener#enable_for?
    def self.enable_for?(_command_runner, _site)
      Nanoc::CLI.verbosity >= 1
    end

    # @param [Enumerable<Nanoc::Int::ItemRep>] reps
    def initialize(reps:)
      @reps = reps
      @telemetry = DDTelemetry.new
    end

    # @see Listener#start
    def start
      stage_stopwatch = DDTelemetry::Stopwatch.new

      on(:stage_started) do |_klass|
        stage_stopwatch.start
      end

      on(:stage_ended) do |klass|
        stage_stopwatch.stop
        name = klass.to_s.sub(/.*::/, '')
        @telemetry.summary(:stages).observe(stage_stopwatch.duration, name)
        stage_stopwatch = DDTelemetry::Stopwatch.new
      end

      outdatedness_rule_stopwatches = {}

      on(:outdatedness_rule_started) do |klass, obj|
        stopwatches = outdatedness_rule_stopwatches.fetch(klass) { outdatedness_rule_stopwatches[klass] = {} }
        stopwatch = stopwatches.fetch(obj) { stopwatches[obj] = DDTelemetry::Stopwatch.new }
        stopwatch.start
      end

      on(:outdatedness_rule_ended) do |klass, obj|
        stopwatches = outdatedness_rule_stopwatches.fetch(klass)
        stopwatch = stopwatches.fetch(obj)
        stopwatch.stop

        name = klass.to_s.sub(/.*::/, '')
        @telemetry.summary(:outdatedness_rules).observe(stopwatch.duration, name)
      end

      filter_stopwatches = {}

      on(:filtering_started) do |rep, _filter_name|
        stopwatch_stack = filter_stopwatches.fetch(rep) { filter_stopwatches[rep] = [] }
        stopwatch_stack << DDTelemetry::Stopwatch.new
        stopwatch_stack.last.start
      end

      on(:filtering_ended) do |rep, filter_name|
        stopwatch = filter_stopwatches.fetch(rep).pop
        stopwatch.stop

        @telemetry.summary(:filters).observe(stopwatch.duration, filter_name.to_s)
      end

      on(:compilation_suspended) do |rep, _exception|
        filter_stopwatches.fetch(rep).each(&:stop)
      end

      on(:compilation_started) do |rep|
        filter_stopwatches.fetch(rep, []).each(&:start)
      end

      phase_stopwatches = {}

      on(:phase_started) do |phase_name, rep|
        stopwatches = phase_stopwatches.fetch(rep) { phase_stopwatches[rep] = {} }
        stopwatches[phase_name] = DDTelemetry::Stopwatch.new.tap(&:start)
      end

      on(:phase_ended) do |phase_name, rep|
        stopwatch = phase_stopwatches.fetch(rep).fetch(phase_name)
        stopwatch.stop

        @telemetry.summary(:phases).observe(stopwatch.duration, phase_name)
      end

      on(:phase_yielded) do |phase_name, rep|
        stopwatch = phase_stopwatches.fetch(rep).fetch(phase_name)
        stopwatch.stop
      end

      on(:phase_resumed) do |phase_name, rep|
        stopwatch = phase_stopwatches.fetch(rep).fetch(phase_name)
        stopwatch.start if stopwatch.stopped?
      end

      on(:phase_aborted) do |phase_name, rep|
        stopwatch = phase_stopwatches.fetch(rep).fetch(phase_name)
        stopwatch.stop if stopwatch.running?

        @telemetry.summary(:phases).observe(stopwatch.duration, phase_name)
      end
    end

    # @see Listener#stop
    def stop
      print_profiling_feedback
      super
    end

    protected

    def table_for_summary(name)
      headers = [name.to_s, 'count', 'min', '.50', '.90', '.95', 'max', 'tot']

      rows = @telemetry.summary(name).map do |filter_name, summary|
        count = summary.count
        min   = summary.min
        p50   = summary.quantile(0.50)
        p90   = summary.quantile(0.90)
        p95   = summary.quantile(0.95)
        tot   = summary.sum
        max   = summary.max

        [filter_name, count.to_s] + [min, p50, p90, p95, max, tot].map { |r| "#{format('%4.2f', r)}s" }
      end

      [headers] + rows
    end

    def table_for_summary_durations(name)
      headers = [name.to_s, 'tot']

      rows = @telemetry.summary(:stages).map do |stage_name, summary|
        [stage_name, "#{format('%4.2f', summary.sum)}s"]
      end

      [headers] + rows
    end

    def print_profiling_feedback
      print_table_for_summary(:filters)
      print_table_for_summary(:phases) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary_duration(:stages) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary(:outdatedness_rules) if Nanoc::CLI.verbosity >= 2
      DDMemoize.print_telemetry(Nanoc::MEMOIZATION_TELEMETRY) if Nanoc::CLI.verbosity >= 2
    end

    def print_table_for_summary(name)
      return if @telemetry.summary(name).empty?

      puts
      print_table(table_for_summary(name))
    end

    def print_table_for_summary_duration(name)
      return if @telemetry.summary(name).empty?

      puts
      print_table(table_for_summary_durations(name))
    end

    def print_table(rows)
      puts DDTelemetry::Table.new(rows).to_s
    end
  end
end
