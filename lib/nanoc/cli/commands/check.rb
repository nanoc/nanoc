# frozen_string_literal: true

usage 'check [options] [names]'
summary 'run issue checks'
description "
Run issue checks on the current site. If the `--all` option is passed, all available issue checks will be run. If the `--deploy` option is passed, the issue checks marked for deployment will be run.
"

flag :a, :all,    'run all checks'
flag :L, :list,   'list all checks'
flag :d, :deploy, 'run checks for deployment'

module Nanoc::CLI::Commands
  class Check < ::Nanoc::CLI::CommandRunner
    def run
      validate_options_and_arguments
      load_site(preprocess: true)

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
        else
          runner.run_specific(arguments)
        end

      unless success
        raise Nanoc::Int::Errors::GenericTrivial, 'One or more checks failed'
      end
    end

    protected

    def validate_options_and_arguments
      if arguments.empty? && !options[:all] && !options[:deploy] && !options[:list]
        raise(
          Nanoc::Int::Errors::GenericTrivial,
          'nothing to do (pass either --all, --deploy or --list or a list of checks)',
        )
      end
    end
  end
end

runner Nanoc::CLI::Commands::Check
