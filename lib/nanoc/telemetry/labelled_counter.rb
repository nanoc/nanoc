module Nanoc::Telemetry
  class LabelledCounter
    def initialize
      @counters = {}
    end

    def increment(labels)
      get(labels).increment
    end

    def get(labels)
      @counters.fetch(labels) { @counters[labels] = Counter.new }
    end

    # TODO: add #labels

    def value(labels)
      get(labels).value
    end

    def values
      @counters.each_with_object({}) do |(labels, counter), res|
        res[labels] = counter.value
      end
    end
  end
end
