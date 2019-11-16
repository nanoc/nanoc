# frozen_string_literal: true

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
  Nanoc::CLI.add_command(Cri::Command.load_file(File.join(commands_path, 'show-rules.rb'), infer_name: true))
end
