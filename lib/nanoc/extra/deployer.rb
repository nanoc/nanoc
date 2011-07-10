# encoding: utf-8

module Nanoc::Extra

  class Deployer

    extend Nanoc::PluginRegistry::PluginMethods

    # TODO document
    # src: does not have a trailing slash
    attr_reader :source_path

    # TODO document
    attr_reader :config

    # TODO document
    attr_reader :dry_run
    alias_method :dry_run?, :dry_run

    # TODO document
    def initialize(source_path, config, params={})
      @source_path  = source_path
      @config       = config
      @dry_run      = params.fetch(:dry_run) { false }
    end

    def run
      raise NotImplementedError.new("Nanoc::Extra::Deployer subclasses must implement #run")
    end

  end

end
