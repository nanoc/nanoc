# frozen_string_literal: true

module Nanoc::Int
  class ActionSequence
    include Nanoc::Core::ContractsSupport
    include Enumerable
    DDMemoize.activate(self)

    attr_reader :item_rep
    attr_reader :actions

    def initialize(item_rep, actions: [])
      @item_rep = item_rep
      @actions = actions
    end

    contract C::None => Numeric
    def size
      @actions.size
    end

    contract Numeric => C::Maybe[Nanoc::Core::ProcessingAction]
    def [](idx)
      @actions[idx]
    end

    contract C::None => C::ArrayOf[Nanoc::Core::ProcessingAction]
    def snapshot_actions
      @actions.select { |a| a.is_a?(Nanoc::Core::ProcessingActions::Snapshot) }
    end

    contract C::None => Array
    def paths
      snapshot_actions.map { |a| [a.snapshot_names, a.paths] }
    end

    memoized def serialize
      serialize_uncached
    end

    contract C::None => Array
    def serialize_uncached
      to_a.map(&:serialize)
    end

    contract C::Func[Nanoc::Core::ProcessingAction => C::Any] => self
    def each
      @actions.each { |a| yield(a) }
      self
    end

    contract C::Func[Nanoc::Core::ProcessingAction => C::Any] => self
    def map
      self.class.new(
        @item_rep,
        actions: @actions.map { |a| yield(a) },
      )
    end

    def snapshots_defs
      is_binary = @item_rep.item.content.binary?
      snapshot_defs = []

      each do |action|
        case action
        when Nanoc::Core::ProcessingActions::Snapshot
          action.snapshot_names.each do |snapshot_name|
            snapshot_defs << Nanoc::Core::SnapshotDef.new(snapshot_name, binary: is_binary)
          end
        when Nanoc::Core::ProcessingActions::Filter
          is_binary = Nanoc::Filter.named!(action.filter_name).to_binary?
        end
      end

      snapshot_defs
    end
  end
end
