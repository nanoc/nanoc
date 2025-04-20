# frozen_string_literal: true

module Nanoc
  module Checking
    # Runner is reponsible for running issue checks.
    #
    # @api private
    class Runner
      # Number of threads to use for running checks.
      NUM_THREADS = 5

      # @param [Nanoc::Core::Site] site The Nanoc site this runner is for
      def initialize(site)
        @site = site

        @log_mutex = Thread::Mutex.new
      end

      def any_enabled_checks?
        !enabled_checks.empty?
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

        checks = classes.map { _1.create(@site) }
        length = classes.map { _1.identifier.to_s.length }.max

        puts 'Running checks…'

        # Create space in terminal to print status of all checks
        classes.count.times { puts }
        cursor_up($stdout, classes.count)

        # Print all checks (all “pending” for now)
        checks.each_with_index do |check, index|
          log_check(index:, topic: format("  %-#{length}s", check.class.identifier.to_s), state: 'pending')
        end

        # Run checks in parallel
        Parallel.each_with_index(checks, in_threads: NUM_THREADS) do |check, index|
          log_check(index:, topic: format("  %-#{length}s", check.class.identifier.to_s), state: colorizer.c('running', :blue))

          check.run

          state = check.issues.empty? ? colorizer.c('ok', :green) : colorizer.c('error', :red)
          log_check(index:, topic: format("  %-#{length}s", check.class.identifier.to_s), state:)
        end

        # Move cursor to below list
        cursor_down($stdout, checks.count)

        # Collect issues
        issues = Set.new
        checks.each do |check|
          issues.merge(check.issues)
        end

        issues
      end

      def log_check(index:, topic:, state:)
        @log_mutex.synchronize do
          cursor_down($stdout, index)

          $stdout << "#{topic}  #{state}"
          erase_rest_of_line($stdout)

          cursor_up($stdout, index)
          go_to_start_of_line($stdout)
        end
      end

      def cursor_up(io, count)
        return if count.zero?

        io << "\e[#{count}A"
      end

      def cursor_down(io, count)
        return if count.zero?

        io << "\e[#{count}B"
      end

      def go_to_start_of_line(io)
        io << "\r"
      end

      def erase_rest_of_line(io)
        io << "\e[K"
      end

      def subject_to_s(str)
        str || '(global)'
      end

      def colorizer
        @_colorizer ||= Nanoc::CLI::ANSIStringColorizer.new($stdout)
      end

      def print_issues(issues)
        return if issues.empty?

        puts 'Issues found!'
        issues.group_by(&:subject).to_a.sort_by { |s| subject_to_s(s.first) }.each do |pair|
          subject = pair.first
          issues  = pair.last
          next if issues.empty?

          puts "  #{subject_to_s(subject)}:"
          issues.each do |i|
            puts "    [ #{colorizer.c('ERROR', :red)} ] #{i.check_class.identifier} - #{i.description}"
          end
        end
      end
    end
  end
end
