# encoding: utf-8

module Nanoc::Extra

  # Watches the working directory for changes and recompiles if necessary.
  class Watcher

    # @return [Hash] The watcher configuration
    attr_reader :config

    # @option params [Hash] :config The watcher configuration
    def initialize(params={})
      @config          = params.fetch(:config)
      @change_detector = params.fetch(:change_detector) { self.new_change_detector }
      @recompiler      = params.fetch(:recompiler)      { self.new_recompiler }
    end

    # Starts the watcher asynchronously. Use {#stop} to stop the watcher.
    #
    # @return [void]
    def start
      self.compile
      @change_detector.start
    end

    # Stops the watcher. Each call to {#start} should be balanced with a call
    # to this method.
    #
    # @return [void]
    def stop
      @change_detector.stop
    end

  protected

    def compile
      puts 'Compiling.'
      @recompiler.recompile
    end

    def recompile
      puts 'Change detected; recompiling.'
      @recompiler.recompile
    end

    def new_change_detector
      change_detector = ChangeDetector.new(self.config)
      change_detector.on_change { self.recompile }
      change_detector
    end

    def new_recompiler
      Recompiler.new(:watcher_config => self.config)
    end

  end

end

require 'nanoc/extra/watcher/change_detector'
require 'nanoc/extra/watcher/recompiler'
