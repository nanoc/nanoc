# encoding: utf-8

module Nanoc::Extra::Checking

  class Checker

    extend Nanoc::PluginRegistry::PluginMethods

    attr_reader :site
    attr_reader :issues

    def initialize(site, issues)
      @site   = site
      @issues = issues
    end

    def run
      raise NotImplementedError.new("Nanoc::Extra::Checking::Checker subclasses must implement #run")
    end

  end

end
