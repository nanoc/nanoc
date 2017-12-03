# frozen_string_literal: true

module Nanoc::Int
  class ProcessingAction
    def serialize
      raise NotImplementedError.new('Nanoc::ProcessingAction subclasses must implement #serialize and #to_s')
    end

    def to_s
      raise NotImplementedError.new('Nanoc::ProcessingAction subclasses must implement #serialize and #to_s')
    end

    def inspect
      format(
        '<%s %s>',
        self.class.to_s,
        serialize[1..-1].map(&:inspect).join(', '),
      )
    end
  end
end
