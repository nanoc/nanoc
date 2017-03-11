usage 'compile [options]'
summary 'compile items of this site'
description <<-EOS
Compile all items of the current site.
EOS
flag nil, :profile, 'profile compilation' if Nanoc::Feature.enabled?(Nanoc::Feature::PROFILER)

module Nanoc::CLI::Commands
  class Compile < ::Nanoc::CLI::CommandRunner
    # Listens to compilation events and reacts to them. This abstract class
    # does not have a real implementation; subclasses should override {#start}
    # and set up notifications to listen to.
    #
    # @abstract Subclasses must override {#start} and may override {#stop}.
    class Listener
      def initialize(*); end

      # @param [Nanoc::CLI::CommandRunner] command_runner The command runner for this listener
      #
      # @return [Boolean] true if this listener should be enabled for the given command runner, false otherwise
      #
      # @abstract Returns `true` by default, but subclasses may override this.
      def self.enable_for?(command_runner) # rubocop:disable Lint/UnusedMethodArgument
        true
      end

      # Starts the listener. Subclasses should override this method and set up listener notifications.
      #
      # @return [void]
      #
      # @abstract
      def start
        raise NotImplementedError, 'Subclasses of Listener should implement #start'
      end

      # Stops the listener. The default implementation removes self from all notification center observers.
      #
      # @return [void]
      def stop; end

      # @api private
      def start_safely
        start
        @_started = true
      end

      # @api private
      def stop_safely
        stop if @_started
        @_started = false
      end
    end

    # Generates diffs for every output file written
    class DiffGenerator < Listener
      # @see Listener#enable_for?
      def self.enable_for?(command_runner)
        command_runner.site.config[:enable_output_diff]
      end

      # @see Listener#start
      def start
        require 'tempfile'
        setup_diffs
        old_contents = {}
        Nanoc::Int::NotificationCenter.on(:will_write_rep, self) do |rep, path|
          old_contents[rep] = File.file?(path) ? File.read(path) : nil
        end
        Nanoc::Int::NotificationCenter.on(:rep_written, self) do |rep, binary, path, _is_created, _is_modified|
          unless binary
            new_contents = File.file?(path) ? File.read(path) : nil
            if old_contents[rep] && new_contents
              generate_diff_for(path, old_contents[rep], new_contents)
            end
            old_contents.delete(rep)
          end
        end
      end

      # @see Listener#stop
      def stop
        super

        Nanoc::Int::NotificationCenter.remove(:will_write_rep, self)
        Nanoc::Int::NotificationCenter.remove(:rep_written, self)

        teardown_diffs
      end

      protected

      def setup_diffs
        @diff_lock    = Mutex.new
        @diff_threads = []
        FileUtils.rm('output.diff') if File.file?('output.diff')
      end

      def teardown_diffs
        @diff_threads.each(&:join)
      end

      def generate_diff_for(path, old_content, new_content)
        return if old_content == new_content

        @diff_threads << Thread.new do
          # Generate diff
          diff = diff_strings(old_content, new_content)
          diff.sub!(/^--- .*/,    '--- ' + path)
          diff.sub!(/^\+\+\+ .*/, '+++ ' + path)

          # Write diff
          @diff_lock.synchronize do
            File.open('output.diff', 'a') { |io| io.write(diff) }
          end
        end
      end

      def diff_strings(a, b)
        require 'open3'

        # Create files
        Tempfile.open('old') do |old_file|
          Tempfile.open('new') do |new_file|
            # Write files
            old_file.write(a)
            old_file.flush
            new_file.write(b)
            new_file.flush

            # Diff
            cmd = ['diff', '-u', old_file.path, new_file.path]
            Open3.popen3(*cmd) do |_stdin, stdout, _stderr|
              result = stdout.read
              return (result == '' ? nil : result)
            end
          end
        end
      rescue Errno::ENOENT
        warn 'Failed to run `diff`, so no diff with the previously compiled ' \
             'content will be available.'
        nil
      end
    end

    # Records the time spent per filter and per item representation
    class TimingRecorder < Listener
      # @see Listener#enable_for?
      def self.enable_for?(command_runner)
        command_runner.options.fetch(:verbose, false)
      end

      # @param [Enumerable<Nanoc::Int::ItemRep>] reps
      def initialize(reps:)
        @reps = reps
      end

      # @see Listener#start
      def start
        @telemetry = Nanoc::Telemetry.new

        stopwatches = {}

        Nanoc::Int::NotificationCenter.on(:filtering_started) do |rep, _filter_name|
          stopwatch_stack = stopwatches.fetch(rep) { stopwatches[rep] = [] }
          stopwatch_stack << Nanoc::Telemetry::Stopwatch.new
          stopwatch_stack.last.start
        end

        Nanoc::Int::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
          stopwatch = stopwatches.fetch(rep).pop
          stopwatch.stop

          @telemetry.summary(:filter_total).observe(stopwatch.duration, filter_name.to_s)
        end

        Nanoc::Int::NotificationCenter.on(:compilation_suspended) do |rep, _exception|
          stopwatches.fetch(rep).each(&:stop)
        end

        Nanoc::Int::NotificationCenter.on(:compilation_started) do |rep|
          stopwatches.fetch(rep, []).each(&:start)
        end
      end

      # @see Listener#stop
      def stop
        print_profiling_feedback
        super
      end

      protected

      def profiling_table
        headers = ['', 'count', 'min', 'avg', 'max', 'tot']

        rows = @telemetry.summary(:filter_total).map do |filter_name, summary|
          count = summary.count
          min   = summary.min
          avg   = summary.avg
          tot   = summary.sum
          max   = summary.max

          [filter_name, count.to_s] + [min, avg, max, tot].map { |r| "#{format('%4.2f', r)}s" }
        end

        [headers] + rows
      end

      def print_profiling_feedback
        return if @telemetry.summary(:filter_total).empty?

        if @reps.any? { |r| !r.compiled? }
          $stderr.puts
          $stderr.puts 'Warning: profiling information may not be accurate because ' \
                       'some items were not compiled.'
        end

        puts
        print_table profiling_table
      end

      def print_table(table)
        lengths = table.transpose.map { |r| r.map(&:size).max }

        print_row(table[0], lengths)

        puts "#{'─' * lengths[0]}─┼─#{lengths[1..-1].map { |length| '─' * length }.join('───')}"

        table[1..-1].each { |row| print_row(row, lengths) }
      end

      def print_row(row, lengths)
        values = row.zip(lengths).map { |text, length| text.rjust length }

        puts values[0] + ' │ ' + values[1..-1].join('   ')
      end
    end

    # Prints debug information (compilation started/ended, filtering started/ended, …)
    class DebugPrinter < Listener
      # @see Listener#enable_for?
      def self.enable_for?(command_runner)
        command_runner.debug?
      end

      # @see Listener#start
      def start
        Nanoc::Int::NotificationCenter.on(:compilation_started) do |rep|
          puts "*** Started compilation of #{rep.inspect}"
        end
        Nanoc::Int::NotificationCenter.on(:compilation_ended) do |rep|
          puts "*** Ended compilation of #{rep.inspect}"
          puts
        end
        Nanoc::Int::NotificationCenter.on(:compilation_suspended) do |rep, e|
          puts "*** Suspended compilation of #{rep.inspect}: #{e.message}"
        end
        Nanoc::Int::NotificationCenter.on(:cached_content_used) do |rep|
          puts "*** Used cached compiled content for #{rep.inspect} instead of recompiling"
        end
        Nanoc::Int::NotificationCenter.on(:filtering_started) do |rep, filter_name|
          puts "*** Started filtering #{rep.inspect} with #{filter_name}"
        end
        Nanoc::Int::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
          puts "*** Ended filtering #{rep.inspect} with #{filter_name}"
        end
        Nanoc::Int::NotificationCenter.on(:dependency_created) do |src, dst|
          puts "*** Dependency created from #{src.inspect} onto #{dst.inspect}"
        end
      end
    end

    # Prints file actions (created, updated, deleted, identical, skipped)
    class FileActionPrinter < Listener
      def initialize(reps:)
        @start_times = {}
        @acc_durations = {}

        @reps = reps
      end

      # @see Listener#start
      def start
        Nanoc::Int::NotificationCenter.on(:compilation_started, self) do |rep|
          @start_times[rep] = Time.now
          @acc_durations[rep] ||= 0.0
        end

        Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) do |rep|
          @acc_durations[rep] += Time.now - @start_times[rep]
        end

        Nanoc::Int::NotificationCenter.on(:rep_written, self) do |rep, _binary, path, is_created, is_modified|
          @acc_durations[rep] += Time.now - @start_times[rep]
          duration = @acc_durations[rep]

          action =
            if is_created then :create
            elsif is_modified then :update
            else :identical
            end
          level =
            if is_created then :high
            elsif is_modified then :high
            else :low
            end
          log(level, action, path, duration)
        end
      end

      # @see Listener#stop
      def stop
        super

        Nanoc::Int::NotificationCenter.remove(:compilation_started, self)
        Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
        Nanoc::Int::NotificationCenter.remove(:rep_written, self)

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

    # Records a profile using StackProf
    class StackProfProfiler < Listener
      PROFILE_FILE = 'tmp/stackprof_profile'.freeze

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

    attr_accessor :listener_classes

    def initialize(options, arguments, command)
      super
      @listener_classes = default_listener_classes
    end

    def run
      time_before = Time.now

      load_site

      puts 'Compiling site…'
      run_listeners_while do
        site.compile
      end

      time_after = Time.now
      puts
      puts "Site compiled in #{format('%.2f', time_after - time_before)}s."
    end

    protected

    def default_listener_classes
      [
        Nanoc::CLI::Commands::Compile::StackProfProfiler,
        Nanoc::CLI::Commands::Compile::DiffGenerator,
        Nanoc::CLI::Commands::Compile::DebugPrinter,
        Nanoc::CLI::Commands::Compile::TimingRecorder,
        Nanoc::CLI::Commands::Compile::FileActionPrinter,
      ]
    end

    def setup_listeners
      @listeners =
        @listener_classes
        .select { |klass| klass.enable_for?(self) }
        .map    { |klass| klass.new(reps: reps) }

      @listeners.each(&:start_safely)
    end

    def listeners
      @listeners
    end

    def run_listeners_while
      setup_listeners
      yield
    ensure
      teardown_listeners
    end

    def teardown_listeners
      return unless @listeners
      @listeners.reverse_each(&:stop_safely)
    end

    def reps
      site.compiler.reps
    end
  end
end

runner Nanoc::CLI::Commands::Compile
