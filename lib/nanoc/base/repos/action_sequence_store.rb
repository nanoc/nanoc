# frozen_string_literal: true

module Nanoc::Int
  # Stores action sequences for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class ActionSequenceStore < ::Nanoc::Int::Store
    def initialize(site: nil)
      super(Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'rule_memory'), 1)

      @action_sequences = {}
    end

    # @param [Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The item representation or
    #   the layout to get the action sequence for
    #
    # @return [Array] The action sequence for the given object
    def [](obj)
      @action_sequences[obj.reference]
    end

    # @param [Nanoc::Int::ItemRep, Nanoc::Int::Layout] obj The item representation or
    #   the layout to set the action sequence for
    #
    # @param [Array] action_sequence The new action sequence to be stored
    #
    # @return [void]
    def []=(obj, action_sequence)
      @action_sequences[obj.reference] = action_sequence
    end

    protected

    # @see Nanoc::Int::Store#data
    def data
      @action_sequences
    end

    # @see Nanoc::Int::Store#data=
    def data=(new_data)
      @action_sequences = new_data
    end
  end
end
