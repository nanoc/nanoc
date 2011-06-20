# encoding: utf-8

require 'cri'

module Nanoc3::CLI

  module Commands
  end

  # TODO document
  def self.run(args)
    self.load_custom_commands
    self.root_command.run(args)
  end

  # @todo Document
  def self.load_custom_commands
    Dir['lib/commands/*.rb'].each do |filename|
      cmd = Nanoc3::CLI.load_command_at(filename)
      Nanoc3::CLI.root_command.add_command(cmd)
    end
  end

private

  # @todo Document
  def self.load_command_at(filename)
    code = File.read(filename)
    cmd = Cri::Command.define(code)
    cmd.modify { name File.basename(filename, '.rb') }
  end

  def self.root_command
    filename = File.dirname(__FILE__) + "/cli/commands/nanoc.rb"
    @root_command ||= self.load_command_at(filename)
  end

end

# Add help command
Nanoc3::CLI.root_command.add_command(
  Cri::Command.new_basic_help)

# Add other commands
Dir[File.dirname(__FILE__) + '/cli/commands/*.rb'].each do |filename|
  next if File.basename(filename, '.rb') == 'nanoc'
  cmd = Nanoc3::CLI.load_command_at(filename)
  Nanoc3::CLI.root_command.add_command(cmd)
end

# Load CLI
require 'nanoc3/cli/logger'
require 'nanoc3/cli/base' # FIXME remove this
