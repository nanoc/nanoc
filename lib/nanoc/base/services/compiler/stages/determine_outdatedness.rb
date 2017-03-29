module Nanoc::Int::Compiler::Stages
  class DetermineOutdatedness
    include Nanoc::Int::ContractsSupport

    def initialize(reps:, outdatedness_checker:, outdatedness_store:)
      @reps = reps
      @outdatedness_checker = outdatedness_checker
      @outdatedness_store = outdatedness_store
    end

    C_OBJ = C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout]

    contract C::HashOf[C_OBJ => Nanoc::Int::ActionSequence], C::Func[C::IterOf[Nanoc::Int::Item] => C::Any] => C::Any
    def run(action_sequences)
      outdated_reps_tmp = @reps.select do |r|
        @outdatedness_store.include?(r) || @outdatedness_checker.outdated?(r, action_sequences)
      end

      outdated_items = outdated_reps_tmp.map(&:item).uniq
      outdated_reps = Set.new(outdated_items.flat_map { |i| @reps[i] })

      outdated_reps.each { |r| @outdatedness_store.add(r) }

      yield(outdated_items)
    end
  end
end
