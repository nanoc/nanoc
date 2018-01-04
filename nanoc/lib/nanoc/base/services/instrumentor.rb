# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Instrumentor
    def self.call(key, *args)
      stopwatch = DDMetrics::Stopwatch.new
      stopwatch.start
      yield
    ensure
      stopwatch.stop
      Nanoc::Int::NotificationCenter.post(key, stopwatch.duration, *args)
    end
  end
end
