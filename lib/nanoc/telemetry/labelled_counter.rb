module Nanoc::Telemetry
  class LabelledCounter
    def initialize
      @counters = {}
    end

    def increment(label)
      get(label).increment
    end

    def get(label)
      @counters.fetch(label) { @counters[label] = Counter.new }
    end

    # TODO: add #empty?

    def value(label)
      get(label).value
    end

    def values
      @counters.each_with_object({}) do |(label, counter), res|
        res[label] = counter.value
      end
    end
  end
end
