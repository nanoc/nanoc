# encoding: utf-8

module Nanoc::Extra

  # Watches the working directory for changes and recompiles if necessary.
  class Watcher

    attr_reader :config

    # TODO document
    def initialize(params={})
      @config          = params.fetch(:config)
      @change_detector = params.fetch(:change_detector) { self.new_change_detector }
      @recompiler      = params.fetch(:recompiler)      { self.new_recompiler }
    end

    # TODO document
    def start
      @recompiler.recompile
      @change_detector.start
    end

    # TODO document
    def stop
      @change_detector.stop
    end

    # TODO document
    def recompile
      puts 'Change detected; recompiling.'
      @recompiler.recompile
    end

    # TODO document
    def new_change_detector
      change_detector = ChangeDetector.new(self.config)
      change_detector.on_change { self.recompile }
      change_detector
    end

    # TODO document
    def new_recompiler
      Recompiler.new(:watcher_config => self.config)
    end

  end

end

require 'nanoc/extra/watcher/change_detector'
require 'nanoc/extra/watcher/recompiler'
