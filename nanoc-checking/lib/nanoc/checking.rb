# frozen_string_literal: true

require 'nanoc-core'
require 'nanoc-cli'

module Nanoc
  module Checking
  end
end

require_relative 'checking/version'
require_relative 'checking/check'
require_relative 'checking/checks'
require_relative 'checking/command_runners'
require_relative 'checking/dsl'
require_relative 'checking/link_collector'
require_relative 'checking/runner'
require_relative 'checking/loader'
require_relative 'checking/issue'

root = File.dirname(__FILE__)
checking_command_path = File.join(root, 'checking', 'commands', 'check.rb')
check_command = Cri::Command.load_file(checking_command_path, infer_name: true)

Nanoc::CLI.after_setup do
  Nanoc::CLI.add_command(check_command)
end
