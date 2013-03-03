# encoding: utf-8

usage       'watch [options]'
summary     'start the watcher'
description <<-EOS
Start the watcher. When a change is detected, the site will be recompiled.
EOS

module Nanoc::CLI::Commands

  class Watch < ::Nanoc::CLI::CommandRunner

    def run
      require_site
      Nanoc::Extra::Watcher.run
    end

  end

end

runner Nanoc::CLI::Commands::Watch
