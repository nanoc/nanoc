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

      # Run all the checkers!
      checkers = []
      classes.each do |klass|
        print "Running #{klass.identifier} checker... "

        checker = klass.new(site)
        checkers << checker
        checker.run

        puts formatted_severity_for(max_severity_for(checker.issues))
      end

      # Print results
      issues = Set.new
      checkers.each { |c| issues.merge c.issues }
      puts
      issues.group_by { |i| i.subject }.each_pair do |subject, issues|
        if ![ :ok, :skipped].include?(max_severity_for(issues)) || options[:verbose]
          puts "#{subject}:"
          issues.each do |i|
            puts "  #{self.issue_string_for(i)}" unless [ :ok, :skipped ].include?(i.severity) && !options[:verbose]
          end
        end
      end
    end

    def max_severity_for(issues)
      issues.max_by { |i| Nanoc::Extra::Checking::Issue::SEVERITIES.index(i.severity) }.severity || :ok
    end

    def formatted_severity_for(severity)
      r = case severity
      when :ok
        [ 'OK',      :green  ]
      when :warning
        [ 'WARNING', :yellow ]
      when :error
        [ 'ERROR',   :red    ]
      when :skipped
        [ 'SKIPPED', :blue   ]
      end
      r.first.center(7).send(r.last)
    end

    def issue_string_for(i)
      "[#{formatted_severity_for(i.severity)}] #{i.checker_class.identifier} - #{i.description}"
    end

  end

end

runner Nanoc::CLI::Commands::Check
