# frozen_string_literal: true

module Nanoc::Telemetry
  class Summary
    class EmptySummaryError < StandardError
      def message
        'Cannot calculate quantile for empty summary'
      end
    end

    def initialize
      @values = []
    end

    def observe(value)
      @values << value
      @sorted_values = nil
    end

    def count
      @values.size
    end

    def sum
      raise EmptySummaryError if @values.empty?
      @values.reduce(:+)
    end

    def avg
      sum / count
    end

    def min
      quantile(0.0)
    end

    def max
      quantile(1.0)
    end

    def quantile(fraction)
      raise EmptySummaryError if @values.empty?

      target = (@values.size - 1) * fraction.to_f
      interp = target % 1.0
      sorted_values[target.floor] * (1.0 - interp) + sorted_values[target.ceil] * interp
    end

    private

    def sorted_values
      @sorted_values ||= @values.sort
    end
  end
end
