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
      @outdatedness_store.clear
      reps_of_items(outdated_items).each { |r| @outdatedness_store.add(r) }
      outdated_items
    end

    private

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
