module Nanoc::Int
  class ActionSequence
    include Nanoc::Int::ContractsSupport
    include Enumerable

    attr_reader :item_rep
    attr_reader :actions

    def initialize(item_rep, actions: [])
      @item_rep = item_rep
      @actions = actions
    end

    def self.build(rep)
      builder = Nanoc::Int::ActionSequenceBuilder.new(rep)
      yield(builder)
      builder.action_sequence
    end

    contract C::None => Numeric
    def size
      @actions.size
    end

    contract Numeric => C::Maybe[Nanoc::Int::ProcessingAction]
    def [](idx)
      @actions[idx]
    end

    contract C::None => C::ArrayOf[Nanoc::Int::ProcessingAction]
    def snapshot_actions
      @actions.select { |a| a.is_a?(Nanoc::Int::ProcessingActions::Snapshot) }
    end

    contract C::None => Array
    def paths
      snapshot_actions.map { |a| [a.snapshot_names, a.paths] }
    end

    # TODO: Add contract
    def serialize
      to_a.map(&:serialize)
    end

    contract C::Func[Nanoc::Int::ProcessingAction => C::Any] => self
    def each
      @actions.each { |a| yield(a) }
      self
    end

    contract C::Func[Nanoc::Int::ProcessingAction => C::Any] => self
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
        when Nanoc::Int::ProcessingActions::Snapshot
          action.snapshot_names.each do |snapshot_name|
            snapshot_defs << Nanoc::Int::SnapshotDef.new(snapshot_name, binary: is_binary)
          end
        when Nanoc::Int::ProcessingActions::Filter
          is_binary = Nanoc::Filter.named!(action.filter_name).to_binary?
        end
      end

      snapshot_defs
    end
  end
end
