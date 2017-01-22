module Nanoc::Int::Compiler::Stages
  class DetermineOutdatedness
    def initialize(reps:, outdatedness_checker:, outdatedness_store:)
      @reps = reps
      @outdatedness_checker = outdatedness_checker
      @outdatedness_store = outdatedness_store
    end

    def run
      outdated_reps_tmp = @reps.select do |r|
        @outdatedness_store.include?(r) || @outdatedness_checker.outdated?(r)
      end

      outdated_items = outdated_reps_tmp.map(&:item).uniq
      outdated_reps = Set.new(outdated_items.flat_map { |i| @reps[i] })

      outdated_reps.each { |r| @outdatedness_store.add(r) }

      yield(outdated_items)
    end
  end
end
