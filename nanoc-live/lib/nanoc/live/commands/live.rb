# frozen_string_literal: true

usage 'live'
summary 'auto-recompile and serve'
description <<~EOS
  Starts the live recompiler along with the static web server. Unless specified,
  the web server will run on port 3000 and listen on all IP addresses. Running
  this static web server requires `adsf` (not `asdf`!).
EOS

required :H, :handler, 'specify the handler to use (webrick/mongrel/...)'
required :o, :host,    'specify the host to listen on (default: 127.0.0.1)'
required :p, :port,    'specify the port to listen on (default: 3000)'

module Nanoc::Live::Commands
  class Live < ::Nanoc::CLI::CommandRunner
    def run
      self.class.enter_site_dir

      Thread.new do
        Thread.current.abort_on_exception = true
        if Thread.current.respond_to?(:report_on_exception)
          Thread.current.report_on_exception = false
        end

        view_options = options.merge('live-reload': true)
        Nanoc::CLI::Commands::View.new(view_options, [], self).run
      end

      Nanoc::Live::LiveRecompiler.new(command_runner: self).run
    end
  end
end

runner Nanoc::Live::Commands::Live
