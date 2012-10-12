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

      @issues << Issue.new(desc, subject, self.class)
    end

    def output_filenames
      Dir[@site.config[:output_dir] + '/**/*'].select{ |f| File.file?(f) }
    end

  end

end
