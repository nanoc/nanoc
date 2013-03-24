# encoding: utf-8

module Nanoc::Extra

  # Watches the working directory for changes and recompiles if necessary.
  class Watcher

    # Runs the watcher.
    #
    # @return [void]
    def run
      require 'pathname'

      require_site

      # Build recompiler
      recompiler = Recompiler.new

      # Rebuild once
      print "Watcher started; compiling the entire site… "
      recompiler.run

      # Build change detector
      change_detector = ChangeDetector.new(self.site.config[:watcher] || {})
      change_detector.on_change do
        # FIXME what is file_path?
        filename = ::Pathname.new(file_path).relative_path_from(::Pathname.new(Dir.getwd)).to_s
        print "Change detected to #{filename}; recompiling… "
        recompiler.run
      end

      # Run
      begin
        change_detector.run
      rescue Interrupt
        change_detector.stop
      end
    end

  end

end

require 'nanoc/extra/watcher/change_detector'
require 'nanoc/extra/watcher/recompiler'
