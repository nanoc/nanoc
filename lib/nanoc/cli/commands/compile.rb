# encoding: utf-8

usage       'compile [options]'
summary     'compile items of this site'
description <<-EOS
Compile all items of the current site.

The compile command will show all items of the site as they are processed. The time spent compiling the item will be printed, as well as a status message, which can be one of the following:

CREATED - The compiled item did not yet exist and has been created

UPDATED - The compiled item did already exist and has been modified

IDENTICAL - The item was deemed outdated and has been recompiled, but the compiled version turned out to be identical to the already existing version

SKIP - The item was deemed not outdated and was therefore not recompiled

EOS

option :a, :all,   '(ignored)'
option :f, :force, '(ignored)'

module Nanoc::CLI::Commands

  class Compile < ::Nanoc::CLI::CommandRunner

    extend Nanoc::Memoization

    # Listens to compilation events and reacts to them. This abstract class
    # does not have a real implementation; subclasses should override {#start}
    # and set up notifications to listen to.
    #
    # @abstract Subclasses must override {#start} and may override {#stop}.
    class Listener

      def initialize(params = {})
      end

      # @param [Nanoc::CLI::CommandRunner] command_runner The command runner for this listener
      #
      # @return [Boolean] true if this listener should be enabled for the given command runner, false otherwise
      #
      # @abstract Returns `true` by default, but subclasses may override this.
      def self.enable_for?(command_runner)
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
      def stop
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
        Nanoc::NotificationCenter.on(:will_write_rep) do |rep, snapshot|
          path = rep.raw_path(:snapshot => snapshot)
          old_contents[rep] = File.file?(path) ? File.read(path) : nil
        end
        Nanoc::NotificationCenter.on(:rep_written) do |rep, path, is_created, is_modified|
          if !rep.binary?
            new_contents = File.file?(path) ? File.read(path) : nil
            if old_contents[rep] && new_contents
              generate_diff_for(rep, old_contents[rep], new_contents)
            end
            old_contents.delete(rep)
          end
        end
      end

      # @see Listener#stop
      def stop
        super
        teardown_diffs
      end

    protected

      def setup_diffs
        @diff_lock    = Mutex.new
        @diff_threads = []
        FileUtils.rm('output.diff') if File.file?('output.diff')
      end

      def teardown_diffs
        @diff_threads.each { |t| t.join }
      end

      def generate_diff_for(rep, old_content, new_content)
        return if old_content == new_content

        @diff_threads << Thread.new do
          # Generate diff
          diff = diff_strings(old_content, new_content)
          diff.sub!(/^--- .*/,    '--- ' + rep.raw_path)
          diff.sub!(/^\+\+\+ .*/, '+++ ' + rep.raw_path)

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
            cmd = [ 'diff', '-u', old_file.path, new_file.path ]
            Open3.popen3(*cmd) do |stdin, stdout, stderr|
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

      # @option params [Array<Nanoc::ItemRep>] :reps The list of item representations in the site
      def initialize(params = {})
        @times = {}

        @reps = params.fetch(:reps)
      end

      # @see Listener#start
      def start
        Nanoc::NotificationCenter.on(:filtering_started) do |rep, filter_name|
          @times[filter_name] ||= []
          @times[filter_name] << { :start => Time.now }
        end
        Nanoc::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
          @times[filter_name].last[:stop] = Time.now
        end
      end

      # @see Listener#stop
      def stop
        print_profiling_feedback
        super
      end

    protected

      def print_profiling_feedback
        # Get max filter length
        max_filter_name_length = durations_per_filter.keys.map { |k| k.to_s.size }.max
        return if max_filter_name_length.nil?

        # Print warning if necessary
        if @reps.any? { |r| !r.compiled? }
          $stderr.puts
          $stderr.puts 'Warning: profiling information may not be accurate because ' +
                       'some items were not compiled.'
        end

        # Print header
        puts
        puts ' ' * max_filter_name_length + ' | count    min    avg    max     tot'
        puts '-' * max_filter_name_length + '-+-----------------------------------'

        durations_per_filter.to_a.sort_by { |r| r[1] }.each do |row|
          print_row(row, max_filter_name_length)
        end
      end

      def print_row(row, length)
        # Extract data
        filter_name, samples = *row

        # Calculate stats
        count = samples.size
        min   = samples.min
        tot   = samples.reduce(0) { |memo, i| memo + i }
        avg   = tot / count
        max   = samples.max

        # Format stats
        count = format('%4d',   count)
        min   = format('%4.2f', min)
        avg   = format('%4.2f', avg)
        max   = format('%4.2f', max)
        tot   = format('%5.2f', tot)

        # Output stats
        key = format("%#{length}s", filter_name)
        puts "#{key} |  #{count}  #{min}s  #{avg}s  #{max}s  #{tot}s"
      end

      def durations_per_filter
        @_durations_per_filter ||= begin
          result = {}
          @times.keys.each do |filter_name|
            durations = durations_for_filter(filter_name)
            if durations
              result[filter_name] = durations
            end
          end
          result
        end
      end

      def durations_for_filter(filter_name)
        result = []
        @times[filter_name].each do |sample|
          if sample[:start] && sample[:stop]
            result << sample[:stop] - sample[:start]
          end
        end
        result
      end

    end

    # Controls garbage collection so that it only occurs once every 20 items
    class GCController < Listener

      # @see Listener#enable_for?
      def self.enable_for?(command_runner)
        !ENV.key?('TRAVIS')
      end

      def initialize(params = {})
        @gc_count = 0
      end

      # @see Listener#start
      def start
        Nanoc::NotificationCenter.on(:compilation_started) do |rep|
          if @gc_count % 20 == 0
            GC.enable
            GC.start
            GC.disable
          end
          @gc_count += 1
        end
      end

      # @see Listener#stop
      def stop
        super
        GC.enable
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
        Nanoc::NotificationCenter.on(:compilation_started) do |rep|
          puts "*** Started compilation of #{rep.inspect}"
        end
        Nanoc::NotificationCenter.on(:compilation_ended) do |rep|
          puts "*** Ended compilation of #{rep.inspect}"
          puts
        end
        Nanoc::NotificationCenter.on(:compilation_failed) do |rep, e|
          puts "*** Suspended compilation of #{rep.inspect}: #{e.message}"
        end
        Nanoc::NotificationCenter.on(:cached_content_used) do |rep|
          puts "*** Used cached compiled content for #{rep.inspect} instead of recompiling"
        end
        Nanoc::NotificationCenter.on(:filtering_started) do |rep, filter_name|
          puts "*** Started filtering #{rep.inspect} with #{filter_name}"
        end
        Nanoc::NotificationCenter.on(:filtering_ended) do |rep, filter_name|
          puts "*** Ended filtering #{rep.inspect} with #{filter_name}"
        end
        Nanoc::NotificationCenter.on(:visit_started) do |item|
          puts "*** Started visiting #{item.inspect}"
        end
        Nanoc::NotificationCenter.on(:visit_ended) do |item|
          puts "*** Ended visiting #{item.inspect}"
        end
        Nanoc::NotificationCenter.on(:dependency_created) do |src, dst|
          puts "*** Dependency created from #{src.inspect} onto #{dst.inspect}"
        end
      end

    end

    # Prints file actions (created, updated, deleted, identical, skipped)
    class FileActionPrinter < Listener

      # @option params [Array<Nanoc::ItemRep>] :reps The list of item representations in the site
      def initialize(params = {})
        @start_times = {}

        @reps = params.fetch(:reps)
      end

      # @see Listener#start
      def start
        Nanoc::NotificationCenter.on(:compilation_started) do |rep|
          @start_times[rep.raw_path] = Time.now
        end
        Nanoc::NotificationCenter.on(:rep_written) do |rep, path, is_created, is_modified|
          duration = path && @start_times[path] ? Time.now - @start_times[path] : nil
          action =
            case
            when is_created  then :create
            when is_modified then :update
            else :identical
            end
          level =
            case
            when is_created  then :high
            when is_modified then :high
            else :low
            end
          log(level, action, path, duration)
        end
      end

      # @see Listener#stop
      def stop
        super
        @reps.select { |r| !r.compiled? }.each do |rep|
          rep.raw_paths.each do |snapshot_name, raw_path|
            log(:low, :skip, raw_path, nil)
          end
        end
      end

    private

      def log(level, action, path, duration)
        Nanoc::CLI::Logger.instance.file(level, action, path, duration)
      end

    end

    def initialize(options, arguments, command, params = {})
      super(options, arguments, command)
      @listener_classes = params.fetch(:listener_classes, default_listener_classes)
    end

    def run
      time_before = Time.now

      load_site
      check_for_deprecated_usage

      puts 'Compiling site…'
      run_listeners_while do
        site.compile
        prune
      end

      time_after = Time.now
      puts
      puts "Site compiled in #{format('%.2f', time_after - time_before)}s."
    end

  protected

    def prune
      if site.config[:prune][:auto_prune]
        Nanoc::Extra::Pruner.new(site, :exclude => prune_config_exclude).run
      end
    end

    def default_listener_classes
      [
        Nanoc::CLI::Commands::Compile::DiffGenerator,
        Nanoc::CLI::Commands::Compile::DebugPrinter,
        Nanoc::CLI::Commands::Compile::TimingRecorder,
        Nanoc::CLI::Commands::Compile::GCController,
        Nanoc::CLI::Commands::Compile::FileActionPrinter
      ]
    end

    def setup_listeners
      @listeners = @listener_classes.
        select { |klass| klass.enable_for?(self) }.
        map    { |klass| klass.new(:reps => reps) }

      @listeners.each { |s| s.start }
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
      @listeners.each { |s| s.stop }
    end

    def reps
      site.items.map { |i| i.reps }.flatten
    end
    memoize :reps

    def check_for_deprecated_usage
      # Check presence of --all option
      if options.key?(:all) || options.key?(:force)
        $stderr.puts 'Warning: the --force option (and its deprecated --all alias) are, as of nanoc 3.2, no longer supported and have no effect.'
      end

      # Warn if trying to compile a single item
      if arguments.size == 1
        $stderr.puts '-' * 80
        $stderr.puts 'Note: As of nanoc 3.2, it is no longer possible to compile a single item. When invoking the “compile” command, all items in the site will be compiled.'
        $stderr.puts '-' * 80
      end
    end

    def prune_config
      site.config[:prune] || {}
    end

    def prune_config_exclude
      prune_config[:exclude] || {}
    end

  end

end

runner Nanoc::CLI::Commands::Compile
