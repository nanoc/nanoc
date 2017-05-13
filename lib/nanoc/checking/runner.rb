# frozen_string_literal: true

module Nanoc::Checking
  # Runner is reponsible for running issue checks.
  #
  # @api private
  class Runner
    CHECKS_FILENAMES = ['Checks', 'Checks.rb', 'checks', 'checks.rb'].freeze

    # @param [Nanoc::Int::Site] site The Nanoc site this runner is for
    def initialize(site)
      @site = site
    end

    # @return [String] The name of the Checks file
    def checks_filename
      @_checks_filename ||= CHECKS_FILENAMES.find { |f| File.file?(f) }
    end

    # @return [Boolean] true if a Checks file exists, false otherwise
    def dsl_present?
      checks_filename && File.file?(checks_filename)
    end
    alias has_dsl? dsl_present?

    # Lists all available checks on stdout.
    #
    # @return [void]
    def list_checks
      load_dsl_if_available

      puts 'Available checks:'
      puts
      puts all_check_classes.map { |i| '  ' + i.identifier.to_s }.sort.join("\n")
    end

    # Runs all checks.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_all
      load_dsl_if_available

      run_check_classes(all_check_classes)
    end

    # Runs the checks marked for deployment.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_for_deploy
      require_dsl

      return true if dsl.nil?
      run_check_classes(check_classes_named(dsl.deploy_checks))
    end

    # Runs the checks with the given names.
    #
    # @param [Array<Symbol>] check_class_names The names of the checks
    #
    # @return [Boolean] true if successful, false otherwise
    def run_specific(check_class_names)
      load_dsl_if_available

      run_check_classes(check_classes_named(check_class_names))
    end

    def load_dsl_if_available
      @dsl_loaded ||= false
      unless @dsl_loaded
        @dsl =
          if dsl_present?
            Nanoc::Checking::DSL.from_file(checks_filename)
          else
            nil
          end
        @dsl_loaded = true
      end
    end

    def require_dsl
      load_dsl_if_available
      if dsl.nil?
        raise Nanoc::Int::Errors::GenericTrivial, "No checks defined (no #{CHECKS_FILENAMES.first} file present)"
      end
    end

    def dsl
      @dsl
    end

    def run_check_classes(classes)
      issues = run_checks(classes)
      print_issues(issues)
      issues.empty? ? true : false
    end

    def all_check_classes
      Nanoc::Checking::Check.all
    end

    def check_classes_named(n)
      n.map do |a|
        klass = Nanoc::Checking::Check.named(a.to_sym)
        raise Nanoc::Int::Errors::GenericTrivial, "Unknown check: #{a}" if klass.nil?
        klass
      end
    end

    def run_checks(classes)
      return [] if classes.empty?

      # TODO: remove me
      @site.compiler.build_reps

      checks = []
      issues = Set.new
      length = classes.map { |c| c.identifier.to_s.length }.max + 18
      classes.each do |klass|
        print format("  %-#{length}s", "Running check #{klass.identifier}… ")

        check = klass.create(@site)
        check.run

        checks << check
        issues.merge(check.issues)

        # TODO: report progress

        puts check.issues.empty? ? 'ok'.green : 'error'.red
      end
      issues
    end

    def subject_to_s(s)
      s || '(global)'
    end

    def print_issues(issues)
      require 'colored'

      return if issues.empty?
      puts 'Issues found!'
      issues.group_by(&:subject).to_a.sort_by { |s| subject_to_s(s.first) }.each do |pair|
        subject = pair.first
        issues  = pair.last
        next if issues.empty?

        puts "  #{subject_to_s(subject)}:"
        issues.each do |i|
          puts "    [ #{'ERROR'.red} ] #{i.check_class.identifier} - #{i.description}"
        end
      end
    end
  end
end
