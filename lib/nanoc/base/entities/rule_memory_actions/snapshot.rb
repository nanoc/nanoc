module Nanoc::Int::RuleMemoryActions
  class Snapshot < Nanoc::Int::RuleMemoryAction
    # snapshot :before_layout
    # snapshot :before_layout, final: true

    attr_reader :snapshot_name
    attr_reader :final
    alias_method :final?, :final

    def initialize(snapshot_name, final)
      @snapshot_name = snapshot_name
      @final = final
    end

    def serialize
      [:snapshot, @snapshot_name, @final]
    end

    def to_s
      "snapshot #{@snapshot_name.inspect}, final: #{@final.inspect}"
    end
  end
end
