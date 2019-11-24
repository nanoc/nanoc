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
require_relative 'checking/dsl'
require_relative 'checking/runner'
require_relative 'checking/loader'
require_relative 'checking/issue'

Nanoc::CLI.after_setup do
  root = File.dirname(__FILE__)
  checking_command_path = File.join(root, 'checking', 'commands', 'check.rb')
  Nanoc::CLI.add_command(Cri::Command.load_file(checking_command_path, infer_name: true))
end
