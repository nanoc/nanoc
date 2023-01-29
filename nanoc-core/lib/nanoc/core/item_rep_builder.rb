# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class ItemRepBuilder
      include Nanoc::Core::ContractsSupport

      contract Nanoc::Core::ActionSequence, Nanoc::Core::ItemRep => C::ArrayOf[Nanoc::Core::SnapshotDef]
      def self.snapshot_defs_for(action_sequence, rep)
        is_binary = rep.item.content.binary?
        snapshot_defs = []

        action_sequence.each do |action|
          case action
          when Nanoc::Core::ProcessingActions::Snapshot
            action.snapshot_names.each do |snapshot_name|
              snapshot_defs << Nanoc::Core::SnapshotDef.new(snapshot_name, binary: is_binary)
            end
          when Nanoc::Core::ProcessingActions::Filter
            is_binary = Nanoc::Core::Filter.named!(action.filter_name).to_binary?
          end
        end

        snapshot_defs
      end

      attr_reader :reps

      contract Nanoc::Core::Site, Nanoc::Core::ActionProvider, Nanoc::Core::ItemRepRepo => C::Any
      def initialize(site, action_provider, reps)
        @site = site
        @action_provider = action_provider
        @reps = reps
      end

      def run
        @site.items.each do |item|
          @action_provider.rep_names_for(item).each do |rep_name|
            @reps << Nanoc::Core::ItemRep.new(item, rep_name)
          end
        end

        action_sequences = Nanoc::Core::ItemRepRouter.new(@reps, @action_provider, @site).run

        @reps.each do |rep|
          rep.snapshot_defs = self.class.snapshot_defs_for(action_sequences[rep], rep)
        end

        action_sequences
      end
    end
  end
end
