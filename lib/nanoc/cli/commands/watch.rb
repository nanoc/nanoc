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

      watcher_config = self.site.config.fetch(:watcher, {})
      watcher = Nanoc::Extra::Watcher.new(:config => watcher_config)

      begin
        watcher.start
        sleep
      rescue Interrupt
        watcher.stop
      end
    end

  end

end

runner Nanoc::CLI::Commands::Watch
