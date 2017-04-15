usage 'compile [options]'
summary 'compile items of this site'
description <<-EOS
Compile all items of the current site.
EOS
flag nil, :profile, 'profile compilation' if Nanoc::Feature.enabled?(Nanoc::Feature::PROFILER)
flag nil, :diff, 'generate diff'

require_relative 'compile_listeners/abstract'
require_relative 'compile_listeners/debug_printer'
require_relative 'compile_listeners/diff_generator'
require_relative 'compile_listeners/file_action_printer'
require_relative 'compile_listeners/stack_prof_profiler'
require_relative 'compile_listeners/timing_recorder'

module Nanoc::CLI::Commands
  class Compile < ::Nanoc::CLI::CommandRunner
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
        Nanoc::CLI::Commands::CompileListeners::StackProfProfiler,
        Nanoc::CLI::Commands::CompileListeners::DiffGenerator,
        Nanoc::CLI::Commands::CompileListeners::DebugPrinter,
        Nanoc::CLI::Commands::CompileListeners::TimingRecorder,
        Nanoc::CLI::Commands::CompileListeners::FileActionPrinter,
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
