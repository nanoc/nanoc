module Nanoc::Int::ProcessingActions
  class Snapshot < Nanoc::Int::ProcessingAction
    # snapshot :before_layout
    # snapshot :before_layout, final: true
    # snapshot :before_layout, path: '/about.md'

    attr_reader :snapshot_name
    attr_reader :final
    attr_reader :path
    alias final? final

    def initialize(snapshot_name, final, path)
      @snapshot_name = snapshot_name
      @final = final
      @path = path
    end

    def serialize
      [:snapshot, @snapshot_name, @final, @path]
    end

    NONE = Object.new

    def copy(path: NONE)
      self.class.new(@snapshot_name, @final, path.equal?(NONE) ? @path : path)
    end

    def to_s
      "snapshot #{@snapshot_name.inspect}, final: #{@final.inspect}, path: #{@path.inspect}"
    end
  end
end
