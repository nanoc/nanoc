# encoding: utf-8

usage       'check [options] [names]'
summary     'run issue checks'
description <<-EOS
Run the given issue checks (or all, if none are given) on the current site.
EOS

flag :a, :all,    'run all checkers'
flag :l, :list,   'list all checkers'
flag :d, :deploy, 'run checkers for deployment'

module Nanoc::CLI::Commands

  class Check < ::Nanoc::CLI::CommandRunner

    def run
      validate_options_and_arguments

      # Load DSL
      if File.exist?('Checkers')
        dsl = Nanoc::Extra::Checking::DSL.from_file('Checkers')
      end

      # List
      if options[:list]
        self.list_checkers
        return
      end

      # Make sure we are in a nanoc site directory
      self.require_site

      # Find and run
      classes = self.find_checker_classes(dsl)
      issues = self.run_checkers(classes)
      self.print_issues(issues)
    end

  protected

    def validate_options_and_arguments
      if arguments.empty? && !options[:all] && !options[:deploy] && !options[:list]
        raise Nanoc::Errors::GenericTrivial,
          "nothing to do (pass either --all, --deploy or --list or a list of checkers)"
      end
    end

    def all_checker_classes
      Nanoc::Extra::Checking::Checker.all.map { |p| p.last }.uniq
    end

    def list_checkers
      puts "Available checkers:"
      puts
      puts all_checker_classes.map { |i| "  " + i.identifier.to_s }.sort.join("\n")
    end

    def checker_classes_named(n)
      classes = n.map do |a|
        klass = Nanoc::Extra::Checking::Checker.named(a)
        raise Nanoc::Errors::GenericTrivial, "Unknown checker: #{a}" if klass.nil?
        klass
      end
    end

    def find_checker_classes(dsl)
      if options[:all]
        return self.all_checker_classes
      elsif options[:deploy]
        if dsl
          return self.checker_classes_named(dsl.deploy_checks)
        end
      else
        return self.checker_classes_named(arguments)
      end

      raise Nanoc::Errors::GenericTrivial, "No checkers to run"
    end

    def run_checkers(classes)
      puts
      checkers = []
      issues = Set.new
      length = classes.map { |c| c.identifier.to_s.length }.max + 20
      classes.each do |klass|
        print format("%-#{length}s", "Running #{klass.identifier} checker... ")

        checker = klass.new(site)
        checkers << checker
        checker.run
        issues.merge checker.issues

        # TODO report progress

        puts issues.empty? ? 'ok'.green : 'error'.red
      end
      issues
    end

    def print_issues(issues)
      require 'colored'

      have_issues = false
      issues.group_by { |i| i.subject }.each_pair do |subject, issues|
        unless issues.empty?
          puts unless have_issues
          have_issues = true
          puts "#{subject}:"
          issues.each do |i|
            puts "  [ #{'ERROR'.red} ] #{i.checker_class.identifier} - #{i.description}"
          end
        end
      end
    end

  end

end

runner Nanoc::CLI::Commands::Check
