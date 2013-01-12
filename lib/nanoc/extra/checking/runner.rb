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

    # Ensures that there is a deployer DSL present.
    #
    # @return [void]
    def require_dsl
      if self.dsl.nil?
        raise Nanoc::Errors::GenericTrivial, "No checks defined (no Checks file present)"
      end
    end

    # Lists all available checks on stdout.
    #
    # @return [void]
    def list_checks
      puts "Available checks:"
      puts
      puts all_check_classes.map { |i| "  " + i.identifier.to_s }.sort.join("\n")
    end

    # Runs all checks.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_all
      self.run_check_classes(self.all_check_classes)
    end

    # Runs the checks marked for deployment.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_for_deploy
      return true if self.dsl.nil?
      self.run_check_classes(self.check_classes_named(self.dsl.deploy_checks))
    end

    # Runs the checks with the given names.
    #
    # @param [Array<Symbol>] check_class_names The names of the checks
    #
    # @return [Boolean] true if successful, false otherwise
    def run_specific(check_class_names)
      self.run_check_classes(self.check_classes_named(check_class_names))
    end

  protected

    def dsl
      @dsl_loaded ||= false
      if !@dsl_loaded
        if File.exist?('Checks')
          @dsl = Nanoc::Extra::Checking::DSL.from_file('Checks')
        else
          @dsl = nil
        end
        @dsl_loaded = true
      end
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
