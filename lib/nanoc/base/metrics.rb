require 'rbconfig'
require 'thread'

module Nanoc
  # @api private
  module Metrics
    # Coordinates creating and asynchronously sending events
    class Collector
      def initialize
        @event_creator = EventCreator.new
        @queue = EventQueue.new(sender: EventSender.new)
      end

      def send_started_event
        @queue << @event_creator.new_started_event
      end

      def send_compiled_event(site)
        @queue << @event_creator.new_compiled_event(site)
      end

      def send_about_to_compile_event(site)
        @queue << @event_creator.new_about_to_compile_event(site)
      end
    end

    # Creates event entities
    class EventCreator
      def new_started_event
        StartedEvent.new(generic_params)
      end

      def new_compiled_event(site)
        # TODO
      end

      def new_about_to_compile_event(site)
        # TODO
      end

      private

      def generic_params
        {
          nanoc_version: nanoc_version,
          ruby_version: ruby_version,
          os: os,
        }
      end

      def nanoc_version
        Nanoc::VERSION
      end

      def ruby_version
        RUBY_VERSION
      end

      def os
        os, version =
          case RbConfig::CONFIG['arch']
          when /aix(\d+)?/
            ['aix', Regexp.last_match(1)]
          when /cygwin/
            ['cygwin', nil]
          when /darwin(\d+)?/
            ['darwin', Regexp.last_match(1)]
          when /^macruby$/
            ['macruby', nil]
          when /freebsd(\d+)?/
            ['freebsd', Regexp.last_match(1)]
          when /hpux(\d+)?/
            ['hpux', Regexp.last_match(1)]
          when /^java$/, /^jruby$/
            ['java', nil]
          when /^java([\d.]*)/
            ['java', Regexp.last_match(1)]
          when /^dalvik(\d+)?$/
            ['dalvik', Regexp.last_match(1)]
          when /^dotnet$/
            ['dotnet', nil]
          when /^dotnet([\d.]*)/
            ['dotnet', Regexp.last_match(1)]
          when /linux/
            ['linux', Regexp.last_match(1)]
          when /mingw32/
            ['mingw32', nil]
          when /(mswin\d+)(\_(\d+))?/
            [Regexp.last_match(1), Regexp.last_match(3)]
          when /netbsdelf/
            ['netbsdelf', nil]
          when /openbsd(\d+\.\d+)?/
            ['openbsd', Regexp.last_match(1)]
          when /bitrig(\d+\.\d+)?/
            ['bitrig', Regexp.last_match(1)]
          when /solaris(\d+\.\d+)?/
            ['solaris', Regexp.last_match(1)]
          else
            ['unknown', nil]
          end

        [os, version].join(' ')
      end
    end

    class Event
      def initialize(params = {})
        @nanoc_version = params.fetch(:nanoc_version)
        @ruby_version = params.fetch(:ruby_version)
        @os = params.fetch(:os)
      end

      def to_json_hash
        {
          nanoc_version: @nanoc_version,
          ruby_version: @ruby_version,
          os: @os,
        }
      end

      def to_json
        JSON.dump(to_json_hash)
      end
    end

    class StartedEvent < Event
    end

    class AboutToCompileEvent < Event
    end

    class CompiledEvent < Event
    end

    # Synchronously sends out events
    class EventSender
      def send_sync(event)
        # TODO
      end
    end

    # Receives events to asynchronously send out
    class EventQueue
      def initialize(sender:)
        @queue = Queue.new
        @thread = nil
        @sender = sender
      end

      def <<(event)
        @queue << event
      end

      private

      def start_if_necessary
        return if @thread

        @thread = Thread.new do
          # TODO: figure out a way to stop this thread
          loop { @sender.send_sync(@queue.pop) }
        end
      end
    end
  end
end
