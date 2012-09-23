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

    SEVERITY_COLORS = {
      :ok      => :green,
      :error   => :red
    }

    def run
      require 'colored'

      # Make sure we have anything to do
      if arguments.empty? && !options[:all] && !options[:deploy] && !options[:list]
        raise Nanoc::Errors::GenericTrivial, "nothing to do (pass either --all, --deploy or --list or a list of checkers)"
      end

      # Load DSL
      if File.exist?('Checkers')
        dsl = Nanoc::Extra::Checking::DSL.from_file('Checkers')
      end

      # List
      if options[:list]
        classes = Nanoc::Extra::Checking::Checker.all.map { |p| p.last }.uniq

        puts "Available checkers:"
        puts
        puts classes.map { |i| "  " + i.identifier.to_s }.sort.join("\n")
        return
      end

      # Make sure we are in a nanoc site directory
      puts "Loading site data..."
      self.require_site

      # Find checker classes
      if options[:all]
        classes = Nanoc::Extra::Checking::Checker.all.map { |p| p.last }.uniq
      elsif options[:deploy]
        # TODO implement
        if dsl
          classes = dsl.deploy_checks.map do |a|
            klass = Nanoc::Extra::Checking::Checker.named(a)
            raise Nanoc::Errors::GenericTrivial, "Unknown checker: #{a}" if klass.nil?
            klass
          end
        else
          classes = []
        end
      else
        classes = arguments.map do |a|
          klass = Nanoc::Extra::Checking::Checker.named(a)
          raise Nanoc::Errors::GenericTrivial, "Unknown checker: #{a}" if klass.nil?
          klass
        end
      end
      if classes.empty?
        raise Nanoc::Errors::GenericTrivial, "No checkers to run"
      end

      # Run all the checkers!
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

        severity = checker.max_severity
        puts severity.to_s.send(SEVERITY_COLORS[severity])
      end

      # Print results
      have_issues = false
      issues.group_by { |i| i.subject }.each_pair do |subject, issues|
        if issues.any? { |i| i.severity == :error } || options[:verbose]
          puts unless have_issues
          have_issues = true
          puts "#{subject}:"
          issues.each do |i|
            if i.severity == :error || options[:verbose]
              severity_string = ('[' + i.severity.to_s.upcase.center(7) + ']').send(SEVERITY_COLORS[i.severity])
              puts "  #{severity_string} #{i.checker_class.identifier} - #{i.description}"
            end
          end
        end
      end
    end

  end

end

runner Nanoc::CLI::Commands::Check
