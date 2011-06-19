# encoding: utf-8

require 'cri'

module Nanoc3::CLI

  module Commands
  end

  # TODO document
  def self.run(args)
    self.root_command.run(args)
  end

private

  def self.root_command
    @root_command ||= self.load_command_named('nanoc')
  end

  def self.load_command_named(name)
    filename = File.dirname(__FILE__) + "/cli/commands/#{name}.rb"
    self.load_command_at(filename)
  end

  def self.load_command_at(filename)
    code = File.read(filename)
    cmd = Cri::Command.define(code)
    cmd.modify { name File.basename(filename, '.rb') }
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
