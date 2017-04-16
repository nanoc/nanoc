module Nanoc::Int
  class ActionSequenceBuilder
    include Nanoc::Int::ContractsSupport

    def initialize(rep)
      @rep = rep
      @action_sequence = Nanoc::Int::ActionSequence.new(rep)
    end

    contract Symbol, Hash => self
    def add_filter(filter_name, params)
      @action_sequence.add_filter(filter_name, params)
      self
    end

    contract String, C::Maybe[Hash] => self
    def add_layout(layout_identifier, params)
      @action_sequence.add_layout(layout_identifier, params)
      self
    end

    contract Symbol, C::Maybe[String] => self
    def add_snapshot(snapshot_name, path)
      @action_sequence.add_snapshot(snapshot_name, path)
      self
    end

    contract C::None => Nanoc::Int::ActionSequence
    def action_sequence
      @action_sequence
    end
  end
end
