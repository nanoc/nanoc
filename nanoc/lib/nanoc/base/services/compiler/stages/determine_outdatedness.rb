# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class DetermineOutdatedness
    include Nanoc::Int::ContractsSupport

    def initialize(reps:, outdatedness_checker:, outdatedness_store:)
      @reps = reps
      @outdatedness_checker = outdatedness_checker
      @outdatedness_store = outdatedness_store
    end

    contract C::None => C::Any
    def run
      outdated_items = select_outdated_items
      outdated_reps = reps_of_items(outdated_items)

      store_outdated_reps(outdated_reps)

      outdated_items
    end

    private

    def store_outdated_reps(reps)
      @outdatedness_store.clear
      reps.each { |r| @outdatedness_store.add(r) }
    end

    def select_outdated_items
      @reps
        .select { |r| outdated?(r) }
        .map(&:item)
        .uniq
    end

    def reps_of_items(items)
      Set.new(items.flat_map { |i| @reps[i] })
    end

    def outdated?(r)
      @outdatedness_store.include?(r) || @outdatedness_checker.outdated?(r)
    end
  end
end
