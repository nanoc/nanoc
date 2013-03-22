# encoding: utf-8

module Nanoc::Extra

  # Watches the working directory for changes and recompiles if necessary.
  class Watcher

    class ChangeDetector

      DEFAULT_DIRS_TO_WATCH  = %w( content layouts lib )
      DEFAULT_FILES_TO_WATCH = %w( nanoc.yaml config.yaml Rules rules Rules.rb rules.rb )

      def initialize(watcher_config={})
        @watcher_config = watcher_config
      end

      def on_change(&block)
        @on_change_block = block
      end

      def dirs_to_watch
        @watcher_config.fetch(:dirs_to_watch, DEFAULT_DIRS_TO_WATCH)
      end

      def files_to_watch
        files = @watcher_config.fetch(:files_to_watch, DEFAULT_FILES_TO_WATCH)
        regex_string = files.map { |fn| '\A' + Regexp.quote(fn) + '\Z' }.join('|')
        Regexp.new(regex_string)
      end

      def run
        require 'listen'

        callback = Proc.new do |modified, added, removed|
          @on_change_block.call
        end

        @listener_root = Listen::MultiListener.new('', :filter => self.files_to_watch).change(&callback)
        @listener = Listen::MultiListener.new(*self.dirs_to_watch).change(&callback)

        @listener_root.start(false)
        @listener.start
      end

      def stop
        @listener.stop
        @listener_root.stop
      end

    end

    class Recompiler

      def initialize(watcher_config)
        @watcher_config = watcher_config
      end

      def recompile
        begin
          site = Nanoc::Site.new('.')
          site.compile
          self.notify_success if self.should_notify_success?
        rescue Exception => e
          self.notify_failure if self.should_notify_failure?
          puts
          Nanoc::CLI::ErrorHandler.print_error(e)
        end
      end

      def should_notify_success?
        @_should_notify_success ||= @watcher_config.fetch(:notify_on_compilation_success, true)
      end

      def should_notify_failure?
        @_should_notify_failure ||= @watcher_config.fetch(:notify_on_compilation_failure, true)
      end

      def notify_success
        self.notify('Compilation complete')
      end

      def notify_failure
        self.notify('Compilation failed')
      end

      def notify(message)
        @_notifier ||= Nanoc::Extra::UserNotifier.new
        @_notifier.notify(message)
      end

    end

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
