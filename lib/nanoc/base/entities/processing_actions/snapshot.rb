module Nanoc::Int::ProcessingActions
  class Snapshot < Nanoc::Int::ProcessingAction
    # snapshot :before_layout
    # snapshot :before_layout, path: '/about.md'

    attr_reader :snapshot_name
    attr_reader :path

    def initialize(snapshot_name, path)
      @snapshot_name = snapshot_name
      @path = path
    end

    def serialize
      [:snapshot, @snapshot_name, true, @path]
    end

    NONE = Object.new

    def copy(path: NONE)
      self.class.new(@snapshot_name, path.equal?(NONE) ? @path : path)
    end

    def to_s
      "snapshot #{@snapshot_name.inspect}, path: #{@path.inspect}"
    end
  end
end
