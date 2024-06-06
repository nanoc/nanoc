# frozen_string_literal: true

module Nanoc
  module Extra
    # @api private
    class SrcsetParser
      class InvalidFormat < ::Nanoc::Core::Error
        def initialize
          super('Invalid srcset format')
        end
      end

      REGEX_REST =
        /
          (               # Zero or one of the following:
            (             #   A width descriptor, consisting of:
              \s+         #     ASCII whitespace
              \d+         #     a valid non-negative integer
              w           #     a U+0077 LATIN SMALL LETTER W character
            )
            |
            (             #   A pixel density descriptor, consisting of
              \s+         #     ASCII whitespace
              (\d*\.)?\d+ #     a valid floating-point number
              x           #     and a U+0078 LATIN SMALL LETTER X character.
            )
          )*
        /x

      def initialize(value)
        @value = value
      end

      def call
        matches = []

        loop do
          match = {}

          scan(/\s*/)
          match[:url] = scan(/[^, ]+/)
          match[:rest] = scan(REGEX_REST)
          scan(/\s*/)

          matches << match

          next if try_scan(/,/)
          break if eos?

          raise(InvalidFormat)
        end

        matches
      rescue InvalidFormat
        @value
      end

      private

      def scan(pattern)
        match = try_scan(pattern)

        match || raise(InvalidFormat)
      end

      def try_scan(pattern)
        scanner.scan(pattern)
      end

      def eos?
        scanner.eos?
      end

      def scanner
        @_scanner ||= StringScanner.new(@value)
      end
    end
  end
end
