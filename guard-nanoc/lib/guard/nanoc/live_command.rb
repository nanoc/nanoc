# frozen_string_literal: true

usage 'live [options]'
summary 'start the web server, and recompile the site when changed'
description <<~EOS
  Start the static web server (like `nanoc view` would), and watch for changes
  in the background (like `guard start` would). See the documentation of those
  two commands for details. The options are forwarded to `nanoc view` only.
EOS

option :H, :handler,       'specify the handler to use (webrick/puma/...)', argument: :required
option :o, :host,          'specify the host to listen on', default: '127.0.0.1', argument: :required
option :p, :port,          'specify the port to listen on', transform: Nanoc::CLI::Transform::Port, default: 3000, argument: :required
flag   :L, :'live-reload', 'reload on changes'

module Guard
  class Nanoc
    class LiveCommand < ::Nanoc::CLI::CommandRunner
      def run
        require 'guard'
        require 'guard/commander'

        if defined?(Nanoc::Live)
          $stderr.puts '-' * 40
          $stderr.puts 'NOTE:'
          $stderr.puts 'You are using the `nanoc live` command provided by `guard-nanoc`, but the `nanoc-live` gem is also installed, which also provides a `nanoc live` command.'
          if defined?(Bundler)
            $stderr.puts 'Recommendation: Remove `guard-nanoc` from your Gemfile.'
          else
            $stderr.puts 'Recommendation: Uninstall `guard-nanoc`.'
          end
          $stderr.puts '-' * 40
        end

        Thread.new do
          break if ENV['__NANOC_DEV_LIVE_DISABLE_VIEW']

          # Crash the entire process if the viewer dies for some reason (e.g.
          # the port is already bound).
          Thread.current.abort_on_exception = true
          ::Nanoc::CLI::Commands::View.new(options, arguments, command).run
        end

        ::Guard.start(no_interactions: true)
      end
    end
  end
end

runner Guard::Nanoc::LiveCommand
