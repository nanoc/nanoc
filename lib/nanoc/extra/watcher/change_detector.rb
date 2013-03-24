# encoding: utf-8

module Nanoc::Extra

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

  end

end
