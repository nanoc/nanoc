module Nanoc::Int
  # @api private
  class ItemRepBuilder
    attr_reader :reps

    def initialize(site, rules_collection, reps)
      @site = site
      @rules_collection = rules_collection
      @reps = reps
    end

    def run
      @site.items.each do |item|
        rep_names_for(item).each do |rep_name|
          @reps << Nanoc::Int::ItemRep.new(item, rep_name)
        end
      end

      Nanoc::Int::ItemRepRouter.new(@reps, @rules_collection, @site).run
    end

    def rep_names_for(item)
      matching_rules = @rules_collection.item_compilation_rules_for(item)
      raise Nanoc::Int::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

      matching_rules.map(&:rep_name).uniq
    end
  end
end
