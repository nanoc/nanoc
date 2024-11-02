# frozen_string_literal: true

module Nanoc
  module Checking
    # Runner is reponsible for running issue checks.
    #
    # @api private
    class Runner
      # @param [Nanoc::Core::Site] site The Nanoc site this runner is for
      def initialize(site)
        @site = site
      end

      def any_enabled_checks?
        enabled_checks.any?
      end

      # Lists all available checks on stdout.
      #
      # @return [void]
      def list_checks
        load_all

        puts 'Available checks:'
        puts
        puts all_check_classes.map { |i| '  ' + i.identifier.to_s }.sort.join("\n")
      end

      # Runs all checks.
      #
      # @return [Boolean] true if successful, false otherwise
      def run_all
        load_all
        run_check_classes(all_check_classes)
      end

      # Runs the checks marked for deployment.
      #
      # @return [Boolean] true if successful, false otherwise
      def run_for_deploy
        # TODO: rename to #run_enabled
        load_all
        run_check_classes(check_classes_named(enabled_checks))
      end

      # Runs the checks with the given names.
      #
      # @param [Array<Symbol>] check_class_names The names of the checks
      #
      # @return [Boolean] true if successful, false otherwise
      def run_specific(check_class_names)
        load_all
        run_check_classes(check_classes_named(check_class_names))
      end

      private

      def loader
        @_loader ||= Nanoc::Checking::Loader.new(config: @site.config)
      end

      def load_all
        loader.run
      end

      def enabled_checks
        loader.enabled_checks
      end

      def run_check_classes(classes)
        issues = run_checks(classes)
        print_issues(issues)
        issues.empty?
      end

      def all_check_classes
        Nanoc::Checking::Check.all
      end

      def check_classes_named(names)
        names.map do |name|
          name = name.to_s.tr('-', '_').to_sym
          klass = Nanoc::Checking::Check.named(name)
          raise Nanoc::Core::TrivialError, "Unknown check: #{name}" if klass.nil?

          klass
        end
      end

      def run_checks(classes)
        return [] if classes.empty?

        # TODO: remove me
        Nanoc::Core::Compiler.new_for(@site).run_until_reps_built

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

      def subject_to_s(str)
        str || '(global)'
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
end
