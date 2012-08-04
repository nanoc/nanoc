# encoding: utf-8

module Nanoc::Extra::Checking

  class Checker

    extend Nanoc::PluginRegistry::PluginMethods

    attr_reader :site
    attr_reader :issues

    def initialize(site)
      @site   = site
      @issues = Set.new
    end

    def run
      raise NotImplementedError.new("Nanoc::Extra::Checking::Checker subclasses must implement #run")
    end

    def add_issue(desc, params={})
      subject  = params.fetch(:subject, nil)
      severity = params.fetch(:severity, :error)

      @issues << Issue.new(desc, subject, severity, self.class)
    end

    def max_severity
      severities = Set.new
      issues.each { |i| severities << i.severity }
      severities.max_by { |s| Issue::SEVERITIES.index(s) } || Issue::SEVERITIES.first
    end

    def output_filenames
      Dir[@site.config[:output_dir] + '/**/*'].select{ |f| File.file?(f) }
    end

  end

end
