module Nanoc::Int::ProcessingActions
  class Snapshot < Nanoc::Int::ProcessingAction
    # snapshot :before_layout
    # snapshot :before_layout, path: '/about.md'

    include Nanoc::Int::ContractsSupport

    attr_reader :snapshot_names
    attr_reader :path

    contract C::IterOf[Symbol], C::Maybe[String] => C::Any
    def initialize(snapshot_names, path)
      @snapshot_names = snapshot_names
      @path = path
    end

    contract C::None => Array
    def serialize
      [:snapshot, @snapshot_names, true, @path]
    end

    NONE = Object.new

    contract C::KeywordArgs[path: C::Optional[C::Any]] => self
    def copy(path: NONE)
      self.class.new(@snapshot_names, path.equal?(NONE) ? @path : path)
    end

    contract C::None => String
    def to_s
      "snapshot #{@snapshot_names.inspect}, path: #{@path.inspect}"
    end
  end
end
