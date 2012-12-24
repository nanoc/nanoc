# encoding: utf-8

usage       'check [options] [names]'
summary     'run issue checks'
description <<-EOS
Run issue checks on the current site. If the --all option is passed, all available issue checks will be run. If the --deploy option is passed, the issue checks marked for deployment will be fun.
EOS

flag :a, :all,    'run all checkers'
flag :l, :list,   'list all checkers'
flag :d, :deploy, 'run checkers for deployment'

module Nanoc::CLI::Commands

  class Check < ::Nanoc::CLI::CommandRunner

    def run
      validate_options_and_arguments
      self.require_site

      runner = Nanoc::Extra::Checking::Runner.new(site)
      if options[:list]
        runner.list_checkers
      elsif options[:all]
        runner.run_all
      elsif options[:deploy]
        runner.require_dsl
        runner.run_for_deploy
      else
        runner.run_specific(arguments)
      end
    end

  protected

    def validate_options_and_arguments
      if arguments.empty? && !options[:all] && !options[:deploy] && !options[:list]
        raise Nanoc::Errors::GenericTrivial,
          "nothing to do (pass either --all, --deploy or --list or a list of checkers)"
      end
    end

  end

end

runner Nanoc::CLI::Commands::Check
