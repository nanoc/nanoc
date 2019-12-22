# frozen_string_literal: true

require 'adsf/live'
require 'listen'
require 'nanoc'
require 'nanoc/orig_cli'

module Nanoc
  module Live
  end
end

require_relative 'live/version'
require_relative 'live/live_recompiler'
require_relative 'live/command_runners/live'

root = File.dirname(__FILE__)
live_command_path = File.join(root, 'live', 'commands', 'live.rb')
command = Cri::Command.load_file(live_command_path, infer_name: true)

Nanoc::CLI.after_setup do
  Nanoc::CLI.add_command(command)
end
