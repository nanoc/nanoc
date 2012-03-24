# encoding: utf-8

module Nanoc::CLI::CleaningStreams

  # An output stream that wraps another output streams and performs cleanup
  # operations before passing it on to the wrapped stream. This can be used to
  # strip ANSI color sequences, for instance.
  #
  # @abstract Subclasses must implement {#clean}.
  class Abstract

    # @param [IO, StringIO] stream The stream to wrap
    def initialize(stream)
      @stream = stream
    end

    # @see IO#write
    def write(s)
      @stream.write(self.clean(s))
    end

    # @see IO#<<
    def <<(s)
      @stream.<<(self.clean(s))
    end

    # @see IO#tty?
    def tty?
      @stream.tty?
    end

    # @see IO#flush
    def flush
      @stream.flush
    end

    # @see IO#tell
    def tell
      @stream.tell
    end

    # @see IO#print
    def print(s)
      @stream.print(self.clean(s))
    end

    # @see IO#puts
    def puts(*s)
      @stream.puts(*s.map { |ss| self.clean(ss) })
    end

    # @see StringIO#string
    def string
      @stream.string
    end

    # @param [String] s The string to clean
    #
    # @return [String] The cleaned string
    #
    # @abstract This method must be implemented in the subclass.
    def clean(s)
      raise NotImplementedError, 'Subclasses of Nanoc::CLI::CleaningStreams::Abstract should implement #clean'
    end

  end

end
