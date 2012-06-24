# encoding: utf-8

# Find all
registry      = Nanoc::PluginRegistry.instance
checker_class = Nanoc::Extra::Checking::Checker
checkers      = registry.find_all(checker_class)
checker_names = checkers.map { |p| p.last }.uniq.map { |c| c.identifier }.sort

usage       'check [names]'
summary     'run issue checks'
description <<-EOS
Run the given issue checks (or all, if none are given) on the current site.

Available checkers: #{checker_names.join(', ')}
EOS

flag :a, :all, 'run all issue checks'

module Nanoc::CLI::Commands

  class Check < ::Nanoc::CLI::CommandRunner

    SEVERITY_COLORS = {
      :ok      => :green,
      :skipped => :blue,
      :warning => :yellow,
      :error   => :red
    }

    def run
      require 'colored'

      # Make sure we are in a nanoc site directory
      puts "Loading site data..."
      self.require_site

      # Find checker classes
      if options[:all]
        classes = Nanoc::Extra::Checking::Checker.all.map { |p| p.last }.uniq
      else
        classes = arguments.map do |a|
          klass = Nanoc::Extra::Checking::Checker.named(a)
          raise Nanoc::Errors::GenericTrivial, "Unknown checker: #{a}" if klass.nil?
          klass
        end
      end
      if classes.empty?
        raise Nanoc::Errors::GenericTrivial, "No checkers specified (use --all to run all checkers)"
      end

      # Run all the checkers!
      puts
      checkers = []
      issues = Set.new
      length = classes.map { |c| c.identifier.length }.max + 20
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
      puts

      # Print results
      issues.group_by { |i| i.subject }.each_pair do |subject, issues|
        if issues.any? { |i| i.important? } || options[:verbose]
          puts "#{subject}:"
          issues.each do |i|
            if i.important? || options[:verbose]
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
