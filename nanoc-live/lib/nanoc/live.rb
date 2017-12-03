# frozen_string_literal: true

require 'adsf/live'
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
  Nanoc::CLI.add_command(Nanoc::CLI.load_command_at(live_command_path))
end
