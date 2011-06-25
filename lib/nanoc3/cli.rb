# encoding: utf-8

require 'cri'

module Nanoc3::CLI

  module Commands
  end

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

  autoload 'Logger',             'nanoc3/cli/logger'
  autoload 'Command',            'nanoc3/cli/command'

  # Invokes the nanoc commandline tool with the given arguments.
  #
  # @param [Array<String>] args An array of commandline arguments
  #
  # @return [void]
  def self.run(args)
    self.setup
    self.load_custom_commands
    self.root_command.run(args)
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
    # Don’t set up twice
    return if @setup

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

    @setup = true
  end

  # Loads the commands in `lib/commands/`.
  #
  # @return [void]
  def self.load_custom_commands
    Dir['lib/commands/*.rb'].each do |filename|
      cmd = Nanoc3::CLI.load_command_at(filename)
      Nanoc3::CLI.root_command.add_command(cmd)
    end
  end

  # Loads the command in the file with the given filename.
  #
  # @param [String] filename The name of the file that contains the command
  #
  # @return [Cri::Command] The loaded command
  def self.load_command_at(filename)
    code = File.read(filename)
    cmd = Cri::Command.define(code)
    cmd.modify { name File.basename(filename, '.rb') }
    cmd
  end

  # @return [Cri::Command] The root command, i.e. the commandline tool itself
  def self.root_command
    @root_command ||= begin
      filename = File.dirname(__FILE__) + "/cli/commands/nanoc.rb"
      self.load_command_at(filename)
    end
  end

end
