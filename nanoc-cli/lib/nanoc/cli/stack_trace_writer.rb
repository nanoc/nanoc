# frozen_string_literal: true

module Nanoc
  module CLI
    class StackTraceWriter
      def initialize(stream)
        @stream = stream
      end

      def write(error, verbose:)
        count = verbose ? -1 : 10

        error.backtrace[0...count].each_with_index do |item, index|
          @stream.puts "  #{index}. #{item}"
        end

        if !verbose && error.backtrace.size > count
          @stream.puts "  ... #{error.backtrace.size - count} lines omitted (see crash.log for details)"
        end
      end
    end
  end
end
