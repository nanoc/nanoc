# frozen_string_literal: true

module Nanoc
  module Core
    # Stores action sequences for objects that can be run through a rule (item
    # representations and layouts).
    #
    # @api private
    class ActionSequenceStore < ::Nanoc::Core::Store
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[config: Nanoc::Core::Configuration] => C::Any
      def initialize(config:)
        super(Nanoc::Core::Store.tmp_path_for(config:, store_name: 'rule_memory'), 2)

        @action_sequences = {}
      end

      # @param [Nanoc::Core::ItemRep, Nanoc::Core::Layout] obj The item representation or
      #   the layout to get the action sequence for
      #
      # @return [Array] The action sequence for the given object
      def [](obj)
        @action_sequences[obj.reference]
      end

      # @param [Nanoc::Core::ItemRep, Nanoc::Core::Layout] obj The item representation or
      #   the layout to set the action sequence for
      #
      # @param [Array] action_sequence The new action sequence to be stored
      #
      # @return [void]
      def []=(obj, action_sequence)
        @action_sequences[obj.reference] = action_sequence
      end

      protected

      # @see Nanoc::Core::Store#data
      def data
        @action_sequences
      end

      # @see Nanoc::Core::Store#data=
      def data=(new_data)
        @action_sequences = new_data
      end
    end
  end
end
