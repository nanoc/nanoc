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
      classes.each do |klass|
        print "Running #{klass.identifier} checker... "

        issues = klass.new(site).run

        puts issues.empty? ? 'ok' : 'not ok'
        issues.each do |e|
          puts "  - #{e}"
        end
      end
    end

  end

end

runner Nanoc::CLI::Commands::Check
