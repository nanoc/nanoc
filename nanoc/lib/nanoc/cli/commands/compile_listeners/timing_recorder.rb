# frozen_string_literal: true

module Nanoc::CLI::Commands::CompileListeners
  class TimingRecorder < Abstract
    attr_reader :stages_summary
    attr_reader :phases_summary
    attr_reader :outdatedness_rules_summary
    attr_reader :filters_summary

    # @see Listener#enable_for?
    def self.enable_for?(_command_runner, _site)
      Nanoc::CLI.verbosity >= 1
    end

    # @param [Enumerable<Nanoc::Int::ItemRep>] reps
    def initialize(reps:)
      @reps = reps

      @stages_summary = DDTelemetry::Summary.new
      @phases_summary = DDTelemetry::Summary.new
      @outdatedness_rules_summary = DDTelemetry::Summary.new
      @filters_summary = DDTelemetry::Summary.new
      @load_stores_summary = DDTelemetry::Summary.new
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
        @stages_summary.observe(stage_stopwatch.duration, name)
        stage_stopwatch = DDTelemetry::Stopwatch.new
      end

      on(:outdatedness_rule_ran) do |duration, klass|
        @outdatedness_rules_summary.observe(duration, klass.to_s.sub(/.*::/, ''))
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

        @filters_summary.observe(stopwatch.duration, filter_name.to_s)
      end

      load_store_stopwatches = {}

      on(:load_store_started) do |klass|
        stopwatch_stack = load_store_stopwatches.fetch(klass) { load_store_stopwatches[klass] = [] }
        stopwatch_stack << DDTelemetry::Stopwatch.new
        stopwatch_stack.last.start
      end

      on(:load_store_ended) do |klass|
        stopwatch = load_store_stopwatches.fetch(klass).pop
        stopwatch.stop

        @load_stores_summary.observe(stopwatch.duration, klass.to_s)
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

        @phases_summary.observe(stopwatch.duration, phase_name)
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

        @phases_summary.observe(stopwatch.duration, phase_name)
      end
    end

    # @see Listener#stop
    def stop
      print_profiling_feedback
      super
    end

    protected

    def table_for_summary(name, summary)
      headers = [name.to_s, 'count', 'min', '.50', '.90', '.95', 'max', 'tot']

      rows = summary.map do |filter_name, stats|
        count = stats.count
        min   = stats.min
        p50   = stats.quantile(0.50)
        p90   = stats.quantile(0.90)
        p95   = stats.quantile(0.95)
        tot   = stats.sum
        max   = stats.max

        [filter_name, count.to_s] + [min, p50, p90, p95, max, tot].map { |r| "#{format('%4.2f', r)}s" }
      end

      [headers] + rows
    end

    def table_for_summary_durations(name, summary)
      headers = [name.to_s, 'tot']

      rows = summary.map do |stage_name, stats|
        [stage_name, "#{format('%4.2f', stats.sum)}s"]
      end

      [headers] + rows
    end

    def print_profiling_feedback
      print_table_for_summary(:filters, @filters_summary)
      print_table_for_summary(:phases, @phases_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary_duration(:stages, @stages_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary(:outdatedness_rules, @outdatedness_rules_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary_duration(:load_stores, @load_stores_summary) if Nanoc::CLI.verbosity >= 2
      DDMemoize.print_telemetry if Nanoc::CLI.verbosity >= 2
    end

    def print_table_for_summary(name, summary)
      return unless summary.any?

      puts
      print_table(table_for_summary(name, summary))
    end

    def print_table_for_summary_duration(name, summary)
      return unless summary.any?

      puts
      print_table(table_for_summary_durations(name, summary))
    end

    def print_table(rows)
      puts DDTelemetry::Table.new(rows).to_s
    end
  end
end
