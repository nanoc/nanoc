module Nanoc::Telemetry
  class LabelledSummary
    def initialize
      @summaries = {}
    end

    def observe(value, labels)
      get(labels).observe(value)
    end

    def get(labels)
      @summaries.fetch(labels) { @summaries[labels] = Summary.new }
    end

    def labels
      @summaries.keys
    end

    def quantile(fraction, labels)
      get(labels).quantile(fraction)
    end

    def map
      @summaries.map { |(labels, summary)| yield(labels, summary) }
    end

    # TODO: add quantiles(fraction)
    # TODO: add min(labels)
    # TODO: add mins
    # TODO: add max(labels)
    # TODO: add maxs
    # TODO: add sum(labels)
    # TODO: add sums
  end
end
