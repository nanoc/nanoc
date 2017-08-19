# frozen_string_literal: true

usage 'live'
summary 'auto-recompile and serve'
description 'TODO'

module Nanoc::CLI::Commands
  class Live < ::Nanoc::CLI::CommandRunner
    def run
      self.class.enter_site_dir

      # TODO: listen web

      Nanoc::Extra::LiveRecompiler.new(command_runner: self).run
    end
  end
end

runner Nanoc::CLI::Commands::Live
