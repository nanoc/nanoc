# frozen_string_literal: true

begin
  require 'cri'
rescue LoadError => e
  $stderr.puts e
  $stderr.puts "If you are using a Gemfile, make sure that the Gemfile contains Nanoc ('gem \"nanoc\"')."
  exit 1
end

require 'nanoc-cli'

# @api private
module Nanoc::OrigCLI
  module Commands
  end
end

Nanoc::CLI.after_setup do
  root = File.dirname(__FILE__)
  commands_path = File.join(root, 'orig_cli', 'commands')
  Nanoc::CLI.add_command(Cri::Command.load_file(File.join(commands_path, 'check.rb'), infer_name: true))
  Nanoc::CLI.add_command(Cri::Command.load_file(File.join(commands_path, 'deploy.rb'), infer_name: true))
end
