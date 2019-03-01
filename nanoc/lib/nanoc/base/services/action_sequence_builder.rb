# frozen_string_literal: true

module Nanoc
  module Int
    class ActionSequenceBuilder
      include Nanoc::Core::ContractsSupport

      # Error that is raised when a snapshot with an existing name is made.
      class CannotCreateMultipleSnapshotsWithSameNameError < ::Nanoc::Error
        include Nanoc::Core::ContractsSupport

        contract Nanoc::Core::ItemRep, Symbol => C::Any
        def initialize(rep, snapshot)
          super("Attempted to create a snapshot with a duplicate name #{snapshot.inspect} for the item rep #{rep}")
        end
      end

      def self.build(rep)
        builder = new(rep)
        yield(builder)
        builder.action_sequence
      end

      def initialize(item_rep)
        @item_rep = item_rep
        @actions = []
      end

      contract Symbol, Hash => self
      def add_filter(filter_name, params)
        @actions << Nanoc::Core::ProcessingActions::Filter.new(filter_name, params)
        self
      end

      contract String, C::Maybe[Hash] => self
      def add_layout(layout_identifier, params)
        @actions << Nanoc::Core::ProcessingActions::Layout.new(layout_identifier, params)
        self
      end

      contract Symbol, C::Maybe[String] => self
      def add_snapshot(snapshot_name, path)
        will_add_snapshot(snapshot_name)
        @actions << Nanoc::Core::ProcessingActions::Snapshot.new([snapshot_name], path ? [path] : [])
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
          raise CannotCreateMultipleSnapshotsWithSameNameError.new(@item_rep, name)
        else
          @_snapshot_names << name
        end
      end
    end
  end
end
