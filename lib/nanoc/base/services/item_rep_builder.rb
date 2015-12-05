module Nanoc::Int
  # @api private
  class ItemRepBuilder
    attr_reader :reps

    def initialize(site, action_provider, rule_memory_calculator, reps)
      @site = site
      @action_provider = action_provider
      @rule_memory_calculator = rule_memory_calculator
      @reps = reps
    end

    def run
      @site.items.each do |item|
        @action_provider.rep_names_for(item).each do |rep_name|
          @reps << Nanoc::Int::ItemRep.new(item, rep_name)
        end
      end

      Nanoc::Int::ItemRepRouter.new(@reps, @rule_memory_calculator, @site).run
    end
  end
end
