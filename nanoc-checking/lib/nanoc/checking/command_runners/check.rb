# frozen_string_literal: true

module Nanoc
  module Checking
    module CommandRunners
      class Check < ::Nanoc::CLI::CommandRunner
        def run
          site = load_site

          runner = Nanoc::Checking::Runner.new(site)

          if options[:list]
            runner.list_checks
            return
          end

          success =
            if options[:all]
              runner.run_all
            elsif options[:deploy]
              runner.run_for_deploy
            elsif arguments.any?
              runner.run_specific(arguments)
            else
              runner.run_for_deploy
            end

          unless success
            raise Nanoc::Core::TrivialError, 'One or more checks failed'
          end
        end
      end
    end
  end
end
