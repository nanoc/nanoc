# encoding: utf-8

module Nanoc::CLI

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
      unless @stream_cleaners.map { |c| c.class }.include?(klass)
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
      @stream_cleaners.delete_if { |c| c.class == klass }
    end

    # @group IO proxy methods

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
      @cached_is_tty ||= @stream.tty?
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

    # @see IO#reopen
    def reopen(*a)
      @stream.reopen(*a)
    end

    # @see File#exist?
    def exist?
      @stream.exist?
    end

    # @see File.exists?
    def exists?
      @stream.exists?
    end

  protected

    def clean(s)
      @stream_cleaners.inject(s) { |m,c| c.clean(m) }
    end

  end

end

