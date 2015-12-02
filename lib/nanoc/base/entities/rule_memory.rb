module Nanoc::Int
  class RuleMemory
    include Enumerable

    def initialize(item_rep)
      @item_rep = item_rep
      @actions = []
    end

    def size
      @actions.size
    end

    def [](idx)
      @actions[idx]
    end

    def add_filter(filter_name, params)
      @actions << Nanoc::Int::RuleMemoryActions::Filter.new(filter_name, params)
    end

    def add_layout(layout_identifier, params)
      @actions << Nanoc::Int::RuleMemoryActions::Layout.new(layout_identifier, params)
    end

    def add_snapshot(snapshot_name, final)
      will_add_snapshot(snapshot_name)
      @actions << Nanoc::Int::RuleMemoryActions::Snapshot.new(snapshot_name, final)
    end

    def add_write(path)
      @actions << Nanoc::Int::RuleMemoryActions::Write.new(path)
    end

    def snapshot_actions
      @actions.select { |a| a.is_a?(Nanoc::Int::RuleMemoryActions::Snapshot) }
    end

    def serialize
      map(&:serialize)
    end

    def each
      @actions.each { |a| yield(a) }
    end

    private

    def will_add_snapshot(name)
      @_snapshot_names ||= Set.new
      if @_snapshot_names.include?(name)
        raise Nanoc::Int::Errors::CannotCreateMultipleSnapshotsWithSameName.new(@item_rep, name)
      else
        @_snapshot_names << name
      end
    end
  end
end
