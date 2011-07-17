# encoding: utf-8

require 'cri'

module Nanoc::CLI

  module Commands
  end

  autoload 'Logger',             'nanoc/cli/logger'
  autoload 'Command',            'nanoc/cli/command'
  autoload 'ErrorHandler',       'nanoc/cli/error_handler'

  # @return [Boolean] true if debug output is enabled, false if not
  #
  # @since 3.2.0
  def self.debug?
    @debug || false
  end

  # @param [Boolean] boolean true if debug output should be enabled,
  #   false if it should not
  #
  # @return [void]
  #
  # @since 3.2.0
  def self.debug=(boolean)
    @debug = boolean
  end

  # Invokes the nanoc commandline tool with the given arguments.
  #
  # @param [Array<String>] args An array of commandline arguments
  #
  # @return [void]
  def self.run(args)
    Nanoc::CLI::ErrorHandler.handle_while do
      self.setup
      self.load_custom_commands
      self.root_command.run(args)
    end
  end

  # Adds the given command to the collection of available commands.
  #
  # @param [Cri::Command] cmd The command to add
  #
  # @return [void]
  def self.add_command(cmd)
    self.root_command.add_command(cmd)
  end

protected

  # Makes the commandline interface ready for using by loading the commands.
  #
  # @return [void]
  def self.setup
    # Reinit
    @root_command = nil

    # Add help command
    help_cmd = Cri::Command.new_basic_help
    self.add_command(help_cmd)

    # Add other commands
    cmd_filenames = Dir[File.dirname(__FILE__) + '/cli/commands/*.rb']
    cmd_filenames.each do |filename|
      next if File.basename(filename, '.rb') == 'nanoc'
      cmd = self.load_command_at(filename)
      self.add_command(cmd)
    end
  end

  # Loads the commands in `commands/`.
  #
  # @return [void]
  def self.load_custom_commands
    self.recursive_contents_of('commands').each do |filename|
      # Create command
      command = Nanoc::CLI.load_command_at(filename)

      # Get supercommand
      pieces = filename.gsub(/^commands\/|\.rb$/, '').split('/')
      pieces = pieces[0, pieces.size-1] || []
      root = Nanoc::CLI.root_command
      supercommand = pieces.inject(root) do |cmd, piece|
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
  def self.load_command_at(filename, command_name=nil)
    # Load
    code = File.read(filename)
    cmd = Cri::Command.define(code)

    # Set name
    command_name ||= File.basename(filename, '.rb')
    cmd.modify { name command_name }

    # Done
    cmd
  end

  # @return [Cri::Command] The root command, i.e. the commandline tool itself
  def self.root_command
    @root_command ||= begin
      filename = File.dirname(__FILE__) + "/cli/commands/nanoc.rb"
      self.load_command_at(filename)
    end
  end

  # @return [Array] The directory contents
  def self.recursive_contents_of(path)
    return [] unless File.directory?(path)
    files, dirs = *Dir[path + '/*'].sort.partition { |e| File.file?(e) }
    dirs.each { |d| files.concat self.recursive_contents_of(d) }
    files
  end

end
