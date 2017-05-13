# frozen_string_literal: true

module Nanoc::Telemetry
  class Counter
    attr_reader :value

    def initialize
      @value = 0
    end

    def increment
      @value += 1
    end
  end
end
