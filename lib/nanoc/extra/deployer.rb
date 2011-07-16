# encoding: utf-8

module Nanoc::Extra

  # Represents a deployer, an object that allows uploading the compiled site
  # to a specific (remote) location.
  #
  # @abstract Subclass and override {#run} to implement a custom filter.
  class Deployer

    extend Nanoc::PluginRegistry::PluginMethods

    # @return [String] The path to the directory that contains the files to
    #   upload. It should not have a trailing slash.
    attr_reader :source_path

    # @return [Hash] The deployer configuration
    attr_reader :config

    # @return [Boolean] true if the deployer should only show what would be
    #   deployed instead of doing the actual deployment
    attr_reader :dry_run
    alias_method :dry_run?, :dry_run

    # @param [String] source_path The path to the directory that contains the
    #   files to upload. It should not have a trailing slash.
    #
    # @return [Hash] config The deployer configuration
    #
    # @option params [Boolean] :dry_run (false) true if the deployer should
    #   only show what would be deployed instead actually deploying
    def initialize(source_path, config, params={})
      @source_path  = source_path
      @config       = config
      @dry_run      = params.fetch(:dry_run) { false }
    end

    # Performs the actual deployment.
    #
    # @abstract
    def run
      raise NotImplementedError.new("Nanoc::Extra::Deployer subclasses must implement #run")
    end

  end

end
