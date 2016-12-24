module Nanoc::Int
  class RuleMemory
    include Nanoc::Int::ContractsSupport
    include Enumerable

    def initialize(item_rep)
      @item_rep = item_rep
      @actions = []
    end

    contract C::None => Numeric
    def size
      @actions.size
    end

    contract Numeric => C::Maybe[Nanoc::Int::ProcessingAction]
    def [](idx)
      @actions[idx]
    end

    contract Symbol, Hash => self
    def add_filter(filter_name, params)
      @actions << Nanoc::Int::ProcessingActions::Filter.new(filter_name, params)
      self
    end

    contract String, C::Maybe[Hash] => self
    def add_layout(layout_identifier, params)
      @actions << Nanoc::Int::ProcessingActions::Layout.new(layout_identifier, params)
      self
    end

    contract Symbol, C::Bool, C::Maybe[String] => self
    def add_snapshot(snapshot_name, final, path)
      will_add_snapshot(snapshot_name) if final
      @actions << Nanoc::Int::ProcessingActions::Snapshot.new(snapshot_name, final, path)
      self
    end

    contract C::None => C::ArrayOf[Nanoc::Int::ProcessingAction]
    def snapshot_actions
      @actions.select { |a| a.is_a?(Nanoc::Int::ProcessingActions::Snapshot) }
    end

    contract C::None => C::Bool
    def any_layouts?
      @actions.any? { |a| a.is_a?(Nanoc::Int::ProcessingActions::Layout) }
    end

    contract C::None => Hash
    def paths
      snapshot_actions.each_with_object({}) do |action, paths|
        paths[action.snapshot_name] = action.path
      end
    end

    # TODO: Add contract
    def serialize
      map(&:serialize)
    end

    contract C::Func[Nanoc::Int::ProcessingAction => C::Any] => self
    def each
      @actions.each { |a| yield(a) }
      self
    end

    # Attempts to merge anonymous snapshots with named ones around it
    def canonicalize
      return if @actions.size < 2

      last_two = @actions.last(2)
      last_two_mergeable =
        last_two.all? { |pa| pa.is_a?(Nanoc::Int::ProcessingActions::Snapshot) } &&
        last_two.last.snapshot_name == :last &&
        last_two.first.snapshot_name.to_s =~ /\A_\d+\z/

      if last_two_mergeable
        @actions[-2, 2] = [Nanoc::Int::ProcessingActions::Snapshot.new(:last, true, last_two.first.path)]
      end
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
