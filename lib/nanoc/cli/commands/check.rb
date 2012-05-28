# encoding: utf-8

usage       'check [names]'
summary     'run issue checks'
description <<-EOS
Run the given issue checks (or all, if none are given) on the current site.
EOS

module Nanoc::CLI::Commands

  class Check < ::Nanoc::CLI::CommandRunner

    def run
      # Make sure we are in a nanoc site directory
      puts "Loading site data..."
      self.require_site

      # Find checker classes
      classes = {}
      arguments.each do |a|
        klass = Nanoc::Extra::Checking::Checker.named(a)
        raise "Unknown checker: #{a}" if klass.nil?
        classes[klass] = a
      end

      # Run all the checkers!
      classes.each_pair do |klass, identifier|
        print "Running #{identifier} checker... "

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
