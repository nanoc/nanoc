# frozen_string_literal: true

module Nanoc
  module Core
    class ActionSequenceBuilder
      include Nanoc::Core::ContractsSupport

      # Error that is raised when a snapshot with an existing name is made.
      class CannotCreateMultipleSnapshotsWithSameNameError < ::Nanoc::Core::Error
        include Nanoc::Core::ContractsSupport

        contract Nanoc::Core::ItemRep, Symbol => C::Any
        def initialize(rep, snapshot)
          super("Attempted to create a snapshot with a duplicate name #{snapshot.inspect} for the item rep #{rep}")
        end
      end

      def self.build
        builder = new
        yield(builder)
        builder.action_sequence
      end

      def initialize
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

      def add_snapshot(snapshot_name, path, rep)
        will_add_snapshot(snapshot_name, rep)
        @actions << Nanoc::Core::ProcessingActions::Snapshot.new([snapshot_name], path ? [path] : [])
        self
      end

      contract C::None => Nanoc::Core::ActionSequence
      def action_sequence
        Nanoc::Core::ActionSequence.new(actions: @actions)
      end

      private

      def will_add_snapshot(name, rep)
        @_snapshot_names ||= Set.new
        if @_snapshot_names.include?(name)
          raise CannotCreateMultipleSnapshotsWithSameNameError.new(rep, name)
        else
          @_snapshot_names << name
        end
      end
    end
  end
end
