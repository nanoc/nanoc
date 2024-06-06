# frozen_string_literal: true

module Nanoc
  module Core
    # Stores item reps (in memory).
    #
    # @api private
    class ItemRepRepo
      include Enumerable

      def initialize
        @reps = []
        @reps_by_item = {}
      end

      def <<(rep)
        @reps << rep

        @reps_by_item[rep.item] ||= []
        @reps_by_item[rep.item] << rep
      end

      def to_a
        @reps
      end

      def each(&)
        @reps.each(&)
        self
      end

      def [](item)
        @reps_by_item.fetch(item, [])
      end
    end
  end
end
