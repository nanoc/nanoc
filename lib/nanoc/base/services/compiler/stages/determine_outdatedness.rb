module Nanoc::Int::Compiler::Stages
  class DetermineOutdatedness
    include Nanoc::Int::ContractsSupport

    def initialize(reps:, outdatedness_checker:, outdatedness_store:)
      @reps = reps
      @outdatedness_checker = outdatedness_checker
      @outdatedness_store = outdatedness_store
    end

    contract Nanoc::Int::ChecksumCollection => C::Any
    def run(_checksums)
      # TODO: Pass checksums to outdatedness checker
      outdated_reps_tmp = @reps.select do |r|
        @outdatedness_store.include?(r) || @outdatedness_checker.outdated?(r)
      end

      outdated_items = outdated_reps_tmp.map(&:item).uniq
      outdated_reps = Set.new(outdated_items.flat_map { |i| @reps[i] })

      outdated_reps.each { |r| @outdatedness_store.add(r) }

      outdated_items
    end
  end
end
