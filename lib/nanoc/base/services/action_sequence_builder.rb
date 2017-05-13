# frozen_string_literal: true

module Nanoc::Int
  class ActionSequenceBuilder
    include Nanoc::Int::ContractsSupport

    def initialize(item_rep)
      @item_rep = item_rep
      @actions = []
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

    contract Symbol, C::Maybe[String] => self
    def add_snapshot(snapshot_name, path)
      will_add_snapshot(snapshot_name)
      @actions << Nanoc::Int::ProcessingActions::Snapshot.new([snapshot_name], path ? [path] : [])
      self
    end

    contract C::None => Nanoc::Int::ActionSequence
    def action_sequence
      Nanoc::Int::ActionSequence.new(@item_rep, actions: @actions)
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
