# frozen_string_literal: true

module Nanoc::CLI::CompileListeners
  class TimingRecorder < Abstract
    attr_reader :stages_summary
    attr_reader :phases_summary
    attr_reader :outdatedness_rules_summary
    attr_reader :filters_summary

    # @see Listener#enable_for?
    def self.enable_for?(_command_runner, _site)
      Nanoc::CLI.verbosity >= 1
    end

    # @param [Enumerable<Nanoc::Core::ItemRep>] reps
    def initialize(reps:)
      @reps = reps

      @stages_summary = DDMetrics::Summary.new
      @phases_summary = DDMetrics::Summary.new
      @outdatedness_rules_summary = DDMetrics::Summary.new
      @filters_summary = DDMetrics::Summary.new
      @load_stores_summary = DDMetrics::Summary.new
      @store_stores_summary = DDMetrics::Summary.new
    end

    # @see Listener#start
    def start
      Nanoc::Core::Instrumentor.enable

      on(:stage_ran) do |duration, klass|
        @stages_summary.observe(duration, name: klass.to_s.sub(/.*::/, ''))
      end

      on(:outdatedness_rule_ran) do |duration, klass|
        @outdatedness_rules_summary.observe(duration, name: klass.to_s.sub(/.*::/, ''))
      end

      filter_stopwatches = {}

      on(:filtering_started) do |rep, _filter_name|
        stopwatch_stack = filter_stopwatches.fetch(rep) { filter_stopwatches[rep] = [] }
        stopwatch_stack << DDMetrics::Stopwatch.new
        stopwatch_stack.last.start
      end

      on(:filtering_ended) do |rep, filter_name|
        stopwatch = filter_stopwatches.fetch(rep).pop
        stopwatch.stop

        @filters_summary.observe(stopwatch.duration, name: filter_name.to_s)
      end

      on(:store_loaded) do |duration, klass|
        @load_stores_summary.observe(duration, name: klass.to_s)
      end

      on(:store_stored) do |duration, klass|
        @store_stores_summary.observe(duration, name: klass.to_s)
      end

      on(:compilation_suspended) do |rep, _target_rep, _snapshot_name|
        filter_stopwatches.fetch(rep).each(&:stop)
      end

      on(:compilation_started) do |rep|
        filter_stopwatches.fetch(rep, []).each(&:start)
      end

      setup_phase_notifications
    end

    # @see Listener#stop
    def stop
      Nanoc::Core::Instrumentor.disable

      print_profiling_feedback
    end

    protected

    def setup_phase_notifications
      stopwatches = {}

      on(:phase_started) do |phase_name, rep|
        stopwatch = stopwatches[[phase_name, rep]] = DDMetrics::Stopwatch.new
        stopwatch.start
      end

      on(:phase_ended) do |phase_name, rep|
        stopwatch = stopwatches[[phase_name, rep]]
        stopwatch.stop

        @phases_summary.observe(stopwatch.duration, name: phase_name)
      end

      on(:phase_yielded) do |phase_name, rep|
        stopwatch = stopwatches[[phase_name, rep]]
        stopwatch.stop
      end

      on(:phase_resumed) do |phase_name, rep|
        # It probably looks weird that a phase can be resumed even though it was not suspended earlier. This can happen when compilation is suspended, where you’d get the sequence started -> suspended -> started -> resumed.
        stopwatch = stopwatches[[phase_name, rep]]
        stopwatch.start unless stopwatch.running?
      end

      on(:phase_aborted) do |phase_name, rep|
        stopwatch = stopwatches[[phase_name, rep]]
        stopwatch.stop if stopwatch.running?

        @phases_summary.observe(stopwatch.duration, name: phase_name)
      end
    end

    def table_for_summary(name, summary)
      headers = [name.to_s, 'count', 'min', '.50', '.90', '.95', 'max', 'tot']

      rows = summary.map do |label, stats|
        name = label.fetch(:name)

        count = stats.count
        min   = stats.min
        p50   = stats.quantile(0.50)
        p90   = stats.quantile(0.90)
        p95   = stats.quantile(0.95)
        tot   = stats.sum
        max   = stats.max

        [name, count.to_s] + [min, p50, p90, p95, max, tot].map { |r| "#{format('%4.2f', r)}s" }
      end

      [headers] + rows
    end

    def table_for_summary_durations(name, summary)
      headers = [name.to_s, 'tot']

      rows = summary.map do |label, stats|
        name = label.fetch(:name)
        [name, "#{format('%4.2f', stats.sum)}s"]
      end

      [headers] + rows
    end

    def print_profiling_feedback
      print_table_for_summary(:filters, @filters_summary)
      print_table_for_summary(:phases, @phases_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary_duration(:stages, @stages_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary(:outdatedness_rules, @outdatedness_rules_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary_duration(:load_stores, @load_stores_summary) if Nanoc::CLI.verbosity >= 2
      print_table_for_summary_duration(:store_stores, @store_stores_summary) if Nanoc::CLI.verbosity >= 2
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
      puts DDMetrics::Table.new(rows)
    end
  end
end
