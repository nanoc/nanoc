module Nanoc::Int
  # @api private
  class ItemRepBuilder
    attr_reader :reps

    def initialize(site, action_provider, reps)
      @site = site
      @action_provider = action_provider
      @reps = reps
    end

    def run
      @site.items.each do |item|
        @action_provider.rep_names_for(item).each do |rep_name|
          @reps << Nanoc::Int::ItemRep.new(item, rep_name)
        end
      end

      Nanoc::Int::ItemRepRouter.new(@reps, @action_provider, @site).run

      @reps.each do |rep|
        rep.snapshot_defs = @action_provider.memory_for(rep).snapshots_defs
      end
    end
  end
end
