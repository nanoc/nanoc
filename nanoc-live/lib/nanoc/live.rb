# frozen_string_literal: true

require 'adsf/live'
require 'listen'
require 'nanoc'
require 'nanoc/cli'

module Nanoc
  module Live
  end
end

require_relative 'live/version'
require_relative 'live/live_recompiler'

Nanoc::CLI.after_setup do
  root = File.dirname(__FILE__)
  live_command_path = File.join(root, 'live', 'commands', 'live.rb')
  Nanoc::CLI.add_command(Cri::Command.load_file(live_command_path, infer_name: true))
end
