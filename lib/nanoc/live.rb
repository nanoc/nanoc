# frozen_string_literal: true

require 'nanoc'
require 'nanoc/cli'

module Nanoc
  module Live
  end
end

require_relative 'live/version'
require_relative 'live/live_recompiler'

Nanoc::CLI.after_setup do
  cmd = Nanoc::CLI.load_command_at(__dir__ + '/live/command.rb', 'live')
  Nanoc::CLI.root_command.add_command(cmd)
end
