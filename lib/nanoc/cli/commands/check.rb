# encoding: utf-8

usage       'check [names]'
summary     'run issue checks'
description <<-EOS
Run the given issue checks (or all, if none are given) on the current site.
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
        classes = []
        arguments.each do |a|
          klass = Nanoc::Extra::Checking::Checker.named(a)
          raise "Unknown checker: #{a}" if klass.nil?
          classes << klass
        end
      end

      # Run all the checkers!
      classes.each do |klass|
        print "Running #{klass.identifier} checker... "

        issues = []
        klass.new(site, issues).run

        puts issues.empty? ? 'ok' : 'not ok'
        issues.each do |e|
          puts "  - #{e}"
        end
      end
    end

  end

end

runner Nanoc::CLI::Commands::Check
