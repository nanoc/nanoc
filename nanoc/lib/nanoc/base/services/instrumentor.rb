# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class Instrumentor
      def self.call(key, *args)
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
