# frozen_string_literal: true

module Nanoc
  module Core
    class ChangesStream
      class ChangesListener
        def initialize(y)
          @y = y
        end

        def unknown
          @y << :unknown
        end

        def lib
          @y << :lib
        end

        def to_stop(&block)
          if block_given?
            @to_stop = block
          else
            @to_stop
          end
        end
      end

      def initialize(enum: nil)
        @enum = enum
        @enum ||=
          Enumerator.new do |y|
            @listener = ChangesListener.new(y)
            yield(@listener)
          end.lazy
      end

      def stop
        @listener&.to_stop&.call
      end

      def map(&)
        self.class.new(enum: @enum.map(&))
      end

      def to_enum
        @enum
      end

      def each(&)
        @enum.each(&)
        nil
      end
    end
  end
end
