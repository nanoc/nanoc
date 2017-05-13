# frozen_string_literal: true

module Nanoc::Telemetry
  class Registry
    def initialize
      @counters = {}
      @summaries = {}
    end

    def counter(name)
      @counters.fetch(name) { @counters[name] = LabelledCounter.new }
    end

    def summary(name)
      @summaries.fetch(name) { @summaries[name] = LabelledSummary.new }
    end
  end
end
