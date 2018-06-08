# frozen_string_literal: true

module Nanoc::CLI
  # @api private
  class StackTraceWriter
    def initialize(stream, forwards:)
      @stream = stream
      @forwards = forwards
    end

    def write(error, verbose:)
      if @forwards
        write_forwards(error, verbose: verbose)
      else
        write_backwards(error, verbose: verbose)
      end
    end

    private

    def write_backwards(error, verbose:)
      count = verbose ? -1 : 10

      error.backtrace[0...count].each_with_index do |item, index|
        @stream.puts "  #{index}. #{item}"
      end

      if !verbose && error.backtrace.size > count
        @stream.puts "  ... #{error.backtrace.size - count} lines omitted (see crash.log for details)"
      end
    end

    def write_forwards(error, verbose:)
      count = 10
      backtrace = verbose ? error.backtrace : error.backtrace.take(count)

      if !verbose && error.backtrace.size > count
        @stream.puts "  ... #{error.backtrace.size - count} lines omitted (see crash.log for details)"
      end

      backtrace.each_with_index.to_a.reverse_each do |(item, index)|
        if index.zero?
          @stream.puts "  #{item}"
        else
          @stream.puts "  #{index}. from #{item}"
        end
      end
    end
  end
end
