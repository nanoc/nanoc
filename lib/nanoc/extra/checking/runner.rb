# encoding: utf-8

module Nanoc::Extra::Checking

  # Runner is reponsible for running issue checks.
  #
  # @api private
  class Runner

    # @param [Nanoc::Site] site The nanoc site this runner is for
    def initialize(site)
      @site = site
    end

    # @param [String] The name of the Checks file
    def checks_filename
      'Checks'
    end

    # @return [Boolean] true if a Checks file exists, false otherwise
    def has_dsl?
      self.checks_filename && File.file?(self.checks_filename)
    end

    # Lists all available checks on stdout.
    #
    # @return [void]
    def list_checks
      self.load_dsl_if_available

      puts "Available checks:"
      puts
      puts all_check_classes.map { |i| "  " + i.identifier.to_s }.sort.join("\n")
    end

    # Runs all checks.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_all
      self.load_dsl_if_available

      self.run_check_classes(self.all_check_classes)
    end

    # Runs the checks marked for deployment.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_for_deploy
      self.require_dsl

      return true if self.dsl.nil?
      self.run_check_classes(self.check_classes_named(self.dsl.deploy_checks))
    end

    # Runs the checks with the given names.
    #
    # @param [Array<Symbol>] check_class_names The names of the checks
    #
    # @return [Boolean] true if successful, false otherwise
    def run_specific(check_class_names)
      self.load_dsl_if_available

      self.run_check_classes(self.check_classes_named(check_class_names))
    end

  protected

    def load_dsl_if_available
      @dsl_loaded ||= false
      if !@dsl_loaded
        if self.has_dsl?
          @dsl = Nanoc::Extra::Checking::DSL.from_file(self.checks_filename)
        else
          @dsl = nil
        end
        @dsl_loaded = true
      end
    end

    def require_dsl
      self.load_dsl_if_available
      if self.dsl.nil?
        raise Nanoc::Errors::GenericTrivial, "No checks defined (no #{CHECKS_FILENAMES.first} file present)"
      end
    end

    def dsl
      @dsl
    end

    def run_check_classes(classes)
      issues = self.run_checks(classes)
      self.print_issues(issues)
      issues.empty? ? true : false
    end

    def all_check_classes
      Nanoc::Extra::Checking::Check.all.map { |p| p.last }.uniq
    end

    def check_classes_named(n)
      classes = n.map do |a|
        klass = Nanoc::Extra::Checking::Check.named(a)
        raise Nanoc::Errors::GenericTrivial, "Unknown check: #{a}" if klass.nil?
        klass
      end
    end

    def run_checks(classes)
      return [] if classes.empty?

      checks = []
      issues = Set.new
      length = classes.map { |c| c.identifier.to_s.length }.max + 18
      classes.each do |klass|
        print format("  %-#{length}s", "Running #{klass.identifier} check… ")

        check = klass.new(@site)
        check.run

        checks << check
        issues.merge(check.issues)

        # TODO report progress

        puts check.issues.empty? ? 'ok'.green : 'error'.red
      end
      issues
    end

    def print_issues(issues)
      require 'colored'

      return if issues.empty?
      puts "Issues found!"
      issues.group_by { |i| i.subject }.to_a.sort_by { |p| p.first }.each do |pair|
        subject = pair.first
        issues  = pair.last
        unless issues.empty?
          puts "  #{subject}:"
          issues.each do |i|
            puts "    [ #{'ERROR'.red} ] #{i.check_class.identifier} - #{i.description}"
          end
        end
      end
    end
  end

end
