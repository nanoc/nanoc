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
flag :L, :'live-reload', 'reload on changes'

module Nanoc::CLI::Commands
  class Live < ::Nanoc::CLI::CommandRunner
    def run
      self.class.enter_site_dir

      Thread.new do
        Thread.current.abort_on_exception = true
        Nanoc::CLI::Commands::View.new(options, [], self).run
      end

      Nanoc::Extra::LiveRecompiler.new(command_runner: self).run
    end
  end
end

runner Nanoc::CLI::Commands::Live
