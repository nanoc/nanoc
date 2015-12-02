module Nanoc::Int::RuleMemoryActions
  class Write < Nanoc::Int::RuleMemoryAction
    # write '/path.html'

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def serialize
      [:write, @path]
    end

    def to_s
      "write #{@path.inspect}"
    end
  end
end
