# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class Instrumentor
      @enabled = false

      def self.enable
        if block_given?
          begin
            enable
            yield
          ensure
            disable
          end
        else
          @enabled = true
        end
      end

      def self.disable
        @enabled = false
      end

      def self.call(key, *args)
        return yield unless @enabled

        begin
          stopwatch = DDMetrics::Stopwatch.new
          stopwatch.start
          yield
        ensure
          stopwatch.stop
          Nanoc::Core::NotificationCenter.post(key, stopwatch.duration, *args)
        end
      end
    end
  end
end
