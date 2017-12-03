# frozen_string_literal: true

module Nanoc::Int::ProcessingActions
  class Snapshot < Nanoc::Int::ProcessingAction
    # snapshot :before_layout
    # snapshot :before_layout, path: '/about.md'

    include Nanoc::Int::ContractsSupport

    attr_reader :snapshot_names
    attr_reader :paths

    contract C::IterOf[Symbol], C::IterOf[String] => C::Any
    def initialize(snapshot_names, paths)
      @snapshot_names = snapshot_names
      @paths = paths
    end

    contract C::None => Array
    def serialize
      [:snapshot, @snapshot_names, true, @paths]
    end

    contract C::KeywordArgs[snapshot_names: C::Optional[C::IterOf[Symbol]], paths: C::Optional[C::IterOf[String]]] => self
    def update(snapshot_names: [], paths: [])
      self.class.new(@snapshot_names + snapshot_names, @paths + paths)
    end

    contract C::None => String
    def to_s
      "snapshot #{@snapshot_names.inspect}, paths: #{@paths.inspect}"
    end
  end
end
