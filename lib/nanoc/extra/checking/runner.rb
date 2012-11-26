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
        raise Nanoc::Errors::GenericTrivial, "No checks defined (no Checkers file present)"
      end
    end

    # Lists all available checkers on stdout.
    #
    # @return [void]
    def list_checkers
      puts "Available checkers:"
      puts
      puts all_checker_classes.map { |i| "  " + i.identifier.to_s }.sort.join("\n")
    end

    # Runs all checkers.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_all
      self.run_checker_classes(self.all_checker_classes)
    end

    # Runs the checkers marked for deployment.
    #
    # @return [Boolean] true if successful, false otherwise
    def run_for_deploy
      return true if self.dsl.nil?
      self.run_checker_classes(self.checker_classes_named(self.dsl.deploy_checks))
    end

    # Runs the checkers with the given names.
    #
    # @param [Array<Symbol>] checker_class_names The names of the checkers
    #
    # @return [Boolean] true if successful, false otherwise
    def run_specific(checker_class_names)
      self.run_checker_classes(self.checker_classes_named(checker_class_names))
    end

  protected

    def dsl
      @dsl_loaded ||= false
      if !@dsl_loaded
        if File.exist?('Checkers')
          @dsl = Nanoc::Extra::Checking::DSL.from_file('Checkers')
        else
          @dsl = nil
        end
        @dsl_loaded = true
      end
      @dsl
    end

    def run_checker_classes(classes)
      issues = self.run_checkers(classes)
      self.print_issues(issues)
      issues.empty? ? true : false
    end

    def all_checker_classes
      Nanoc::Extra::Checking::Checker.all.map { |p| p.last }.uniq
    end

    def checker_classes_named(n)
      classes = n.map do |a|
        klass = Nanoc::Extra::Checking::Checker.named(a)
        raise Nanoc::Errors::GenericTrivial, "Unknown checker: #{a}" if klass.nil?
        klass
      end
    end

    def run_checkers(classes)
      return [] if classes.empty?

      checkers = []
      issues = Set.new
      length = classes.map { |c| c.identifier.to_s.length }.max + 18
      classes.each do |klass|
        print format("  %-#{length}s", "Running #{klass.identifier} checker… ")

        checker = klass.new(@site)
        checkers << checker
        checker.run
        issues.merge checker.issues

        # TODO report progress

        puts issues.empty? ? 'ok'.green : 'error'.red
      end
      issues
    end

    def print_issues(issues)
      require 'colored'

      return if issues.empty?
      puts "Issues found!"
      issues.group_by { |i| i.subject }.each_pair do |subject, issues|
        unless issues.empty?
          puts "  #{subject}:"
          issues.each do |i|
            puts "    [ #{'ERROR'.red} ] #{i.checker_class.identifier} - #{i.description}"
          end
        end
      end
    end
  end

end
