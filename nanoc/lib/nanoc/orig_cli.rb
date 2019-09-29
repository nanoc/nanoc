# frozen_string_literal: true

begin
  require 'cri'
rescue LoadError => e
  $stderr.puts e
  $stderr.puts "If you are using a Gemfile, make sure that the Gemfile contains Nanoc ('gem \"nanoc\"')."
  exit 1
end

# @api private
module Nanoc::OrigCLI
  module Commands
  end
end

require_relative 'orig_cli/ansi_string_colorizer'
require_relative 'orig_cli/logger'
require_relative 'orig_cli/command_runner'
require_relative 'orig_cli/cleaning_stream'
require_relative 'orig_cli/stream_cleaners'
require_relative 'orig_cli/error_handler'
require_relative 'orig_cli/stack_trace_writer'
require_relative 'orig_cli/transform'

require_relative 'orig_cli/commands/compile_listeners/abstract'
require_relative 'orig_cli/commands/compile_listeners/debug_printer'
require_relative 'orig_cli/commands/compile_listeners/diff_generator'
require_relative 'orig_cli/commands/compile_listeners/file_action_printer'
require_relative 'orig_cli/commands/compile_listeners/timing_recorder'
require_relative 'orig_cli/commands/compile_listeners/aggregate'

# @api private
module Nanoc::OrigCLI
  # @return [Boolean] true if debug output is enabled, false if not
  def self.debug?
    @debug || false
  end

  # @param [Boolean] boolean true if debug output should be enabled,
  #   false if it should not
  #
  # @return [void]
  def self.debug=(boolean)
    @debug = boolean
  end

  def self.verbosity
    @verbosity || 0
  end

  def self.verbosity=(val)
    @verbosity = val
  end

  # Invokes the Nanoc command-line tool with the given arguments.
  #
  # @param [Array<String>] args An array of command-line arguments
  #
  # @return [void]
  def self.run(args)
    Nanoc::OrigCLI::ErrorHandler.handle_while do
      setup
      root_command.run(args)
    end
  end

  # @return [Cri::Command] The root command, i.e. the command-line tool itself
  def self.root_command
    @root_command
  end

  # Adds the given command to the collection of available commands.
  #
  # @param [Cri::Command] cmd The command to add
  #
  # @return [void]
  def self.add_command(cmd)
    root_command.add_command(cmd)
  end

  # Schedules the given block to be executed after the CLI has been set up.
  #
  # @return [void]
  def self.after_setup(&block)
    # TODO: decide what should happen if the CLI is already set up
    add_after_setup_proc(block)
  end

  # Makes the command-line interface ready for use.
  #
  # @return [void]
  def self.setup
    setup_cleaning_streams
    setup_commands
    load_custom_commands
    after_setup_procs.each(&:call)
  end

  # Sets up the root command and base subcommands.
  #
  # @return [void]
  def self.setup_commands
    # Reinit
    @root_command = nil

    # Add root command
    filename = __dir__ + '/orig_cli/commands/nanoc.rb'
    @root_command = Cri::Command.load_file(filename, infer_name: true)

    # Add help command
    help_cmd = Cri::Command.new_basic_help
    add_command(help_cmd)

    # Add other commands
    cmd_filenames = Dir[__dir__ + '/orig_cli/commands/*.rb']
    cmd_filenames.each do |cmd_filename|
      basename = File.basename(cmd_filename, '.rb')

      next if basename == 'nanoc'

      cmd = Cri::Command.load_file(cmd_filename, infer_name: true)
      add_command(cmd)
    end

    if defined?(Bundler)
      # Discover external commands through Bundler
      begin
        Bundler.require(:nanoc)
      rescue Bundler::GemfileNotFound
        # When running Nanoc with Bundler being defined but
        # no gemfile being present (rubygems automatically loads
        # Bundler when executing from command line), don't crash.
      end
    end
  end

  # Loads site-specific commands.
  #
  # @return [void]
  def self.load_custom_commands
    if Nanoc::Core::SiteLoader.cwd_is_nanoc_site?
      config = Nanoc::Core::ConfigLoader.new.new_from_cwd
      config[:commands_dirs].each do |path|
        load_commands_at(path)
      end
    end
  end

  def self.load_commands_at(path)
    recursive_contents_of(path).each do |filename|
      # Create command
      command = Cri::Command.load_file(filename, infer_name: true)

      # Get supercommand
      pieces = filename.gsub(/^#{path}\/|\.rb$/, '').split('/')
      pieces = pieces[0, pieces.size - 1] || []
      root = Nanoc::OrigCLI.root_command
      supercommand = pieces.reduce(root) do |cmd, piece|
        cmd.nil? ? nil : cmd.command_named(piece)
      end

      # Add to supercommand
      if supercommand.nil?
        raise "Cannot load command at #{filename} because its supercommand cannot be found"
      end

      supercommand.add_command(command)
    end
  end

  # Loads the command in the file with the given filename.
  #
  # @param [String] filename The name of the file that contains the command
  #
  # @return [Cri::Command] The loaded command
  #
  # @deprecated
  def self.load_command_at(filename)
    # TODO: remove me one guard-nanoc is in this repo
    Cri::Command.load_file(filename, infer_name: true)
  end

  # @return [Array] The directory contents
  def self.recursive_contents_of(path)
    return [] unless File.directory?(path)

    files, dirs = *Dir[path + '/*'].sort.partition { |e| File.file?(e) }
    dirs.each { |d| files.concat recursive_contents_of(d) }
    files
  end

  # Wraps the given stream in a cleaning stream. The cleaning streams will
  # have the proper stream cleaners configured.
  #
  # @param [IO] io The stream to wrap
  #
  # @return [::Nanoc::OrigCLI::CleaningStream]
  def self.wrap_in_cleaning_stream(io)
    cio = ::Nanoc::OrigCLI::CleaningStream.new(io)

    unless enable_utf8?(io)
      cio.add_stream_cleaner(Nanoc::OrigCLI::StreamCleaners::UTF8)
    end

    unless enable_ansi_colors?(io)
      cio.add_stream_cleaner(Nanoc::OrigCLI::StreamCleaners::ANSIColors)
    end

    cio
  end

  # Wraps `$stdout` and `$stderr` in appropriate cleaning streams.
  #
  # @return [void]
  def self.setup_cleaning_streams
    $stdout = wrap_in_cleaning_stream($stdout)
    $stderr = wrap_in_cleaning_stream($stderr)
  end

  # @return [Boolean] true if UTF-8 support is present, false if not
  def self.enable_utf8?(io)
    return true unless io.tty?

    %w[LC_ALL LC_CTYPE LANG].any? { |e| ENV[e] =~ /UTF/i }
  end

  # @return [Boolean] true if color support is present, false if not
  def self.enable_ansi_colors?(io)
    io.tty? && !ENV.key?('NO_COLOR')
  end

  def self.after_setup_procs
    @after_setup_procs || []
  end

  def self.add_after_setup_proc(proc)
    @after_setup_procs ||= []
    @after_setup_procs << proc
  end
end
