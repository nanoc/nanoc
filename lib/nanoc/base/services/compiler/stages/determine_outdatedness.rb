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
      outdated_reps = @reps.select { |r| outdated?(r) }

      outdated_items = outdated_reps.map(&:item).uniq

      @outdatedness_store.clear

      reps_of_outdated_items = Set.new(outdated_items.flat_map { |i| @reps[i] })
      reps_of_outdated_items.each { |r| @outdatedness_store.add(r) }

      outdated_items
    end

    private

    def outdated?(r)
      @outdatedness_store.include?(r) || @outdatedness_checker.outdated?(r)
    end
  end
end
