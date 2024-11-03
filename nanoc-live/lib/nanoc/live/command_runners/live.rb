# frozen_string_literal: true

module Nanoc
  module Live
    module CommandRunners
      class Live < ::Nanoc::CLI::CommandRunner
        def run
          if defined?(Guard::Nanoc)
            $stderr.puts '-' * 40
            $stderr.puts 'NOTE:'
            $stderr.puts 'You are using the `nanoc live` command provided by `nanoc-live`, but the `guard-nanoc` gem is also installed, which also provides a `nanoc live` command.'
            if defined?(Bundler)
              $stderr.puts 'Recommendation: Remove `guard-nanoc` from your Gemfile, either manually or by running the `bundle remove guard-nanoc` command.'
            else
              $stderr.puts 'Recommendation: Uninstall `guard-nanoc` (run the `gem uninstall guard-nanoc` command).'
            end
            $stderr.puts '-' * 40
          end

          self.class.enter_site_dir

          Thread.new do
            Thread.current.abort_on_exception = true
            if Thread.current.respond_to?(:report_on_exception)
              Thread.current.report_on_exception = false
            end

            view_options = options.merge('live-reload': true)
            Nanoc::CLI::Commands::View.new(view_options, [], self).run
          end

          Nanoc::Live::LiveRecompiler.new(command_runner: self, focus: options[:focus]).run
        end
      end
    end
  end
end
