# frozen_string_literal: true

module Nanoc
  module CLI
    # An output stream that passes output through stream cleaners. This can be
    # used to strip ANSI color sequences, for instance.
    class CleaningStream
      # @param [IO, StringIO] stream The stream to wrap
      def initialize(stream)
        @stream = stream
        @stream_cleaners = []
      end

      # Adds a stream cleaner for the given class to this cleaning stream. If the
      # cleaning stream already has the given stream cleaner, nothing happens.
      #
      # @param [Nanoc::CLI::StreamCleaners::Abstract] klass The class of the
      #   stream cleaner to add
      #
      # @return [void]
      def add_stream_cleaner(klass)
        unless @stream_cleaners.map(&:class).include?(klass)
          @stream_cleaners << klass.new
        end
      end

      # Removes the stream cleaner for the given class from this cleaning stream.
      # If the cleaning stream does not have the given stream cleaner, nothing
      # happens.
      #
      # @param [Nanoc::CLI::StreamCleaners::Abstract] klass The class of the
      #   stream cleaner to add
      #
      # @return [void]
      def remove_stream_cleaner(klass)
        @stream_cleaners.delete_if { |c| c.instance_of?(klass) }
      end

      # @group IO proxy methods

      # @see IO#write
      def write(str)
        _nanoc_swallow_broken_pipe_errors_while do
          @stream.write(_nanoc_clean(str))
        end
      end

      # @see IO#<<
      def <<(str)
        _nanoc_swallow_broken_pipe_errors_while do
          @stream << (_nanoc_clean(str))
        end
      end

      # @see IO#tty?
      def tty?
        @_tty_eh ||= @stream.tty? # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      # @see IO#isatty
      def isatty
        tty?
      end

      # @see IO#flush
      def flush
        _nanoc_swallow_broken_pipe_errors_while do
          @stream.flush
        end
      end

      # @see IO#tell
      def tell
        @stream.tell
      end

      # @see IO#print
      def print(str)
        _nanoc_swallow_broken_pipe_errors_while do
          @stream.print(_nanoc_clean(str))
        end
      end

      # @see IO#printf
      def printf(*args)
        @stream.printf(*args)
      end

      # @see IO#puts
      def puts(*str)
        _nanoc_swallow_broken_pipe_errors_while do
          @stream.puts(*str.map { |ss| _nanoc_clean(ss) })
        end
      end

      # @see StringIO#string
      def string
        @stream.string
      end

      # @see IO#reopen
      def reopen(*args)
        @stream.reopen(*args)
      end

      # @see IO#close
      def close
        @stream.close
      end

      # @see IO#closed?
      def closed?
        @stream.closed?
      end

      # @see File#exist?
      def exist?
        @stream.exist?
      end

      # @see File.exists?
      def exists?
        @stream.exists?
      end

      # @see IO.winsize
      def winsize
        @stream.winsize
      end

      # @see IO.winsize=
      def winsize=(arg)
        @stream.winsize = arg
      end

      # @see IO.sync
      def sync
        @stream.sync
      end

      # @see IO.sync=
      def sync=(arg)
        @stream.sync = arg
      end

      # @see IO.sync=
      def external_encoding
        @stream.external_encoding
      end

      # @see ARGF.set_encoding
      def set_encoding(*args)
        @stream.set_encoding(*args)
      end

      protected

      def _nanoc_clean(str)
        @stream_cleaners.reduce(str.to_s.scrub) { |acc, elem| elem.clean(acc) }
      end

      def _nanoc_swallow_broken_pipe_errors_while
        yield
      rescue Errno::EPIPE
      end
    end
  end
end
