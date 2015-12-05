module Nanoc::Int
  # @api private
  class CompilerLoader
    def load(site)
      rules_collection = Nanoc::Int::RulesCollection.new

      rule_memory_store = Nanoc::Int::RuleMemoryStore.new

      rule_memory_calculator =
        Nanoc::RuleDSL::RuleMemoryCalculator.new(
          rules_collection: rules_collection, site: site)

      dependency_store =
        Nanoc::Int::DependencyStore.new(site.items.to_a + site.layouts.to_a)

      checksum_store =
        Nanoc::Int::ChecksumStore.new(site: site)

      item_rep_repo = Nanoc::Int::ItemRepRepo.new

      outdatedness_checker =
        Nanoc::Int::OutdatednessChecker.new(
          site: site,
          checksum_store: checksum_store,
          dependency_store: dependency_store,
          rules_collection: rules_collection,
          rule_memory_store: rule_memory_store,
          rule_memory_calculator: rule_memory_calculator,
          reps: item_rep_repo,
        )

      params = {
        compiled_content_cache: Nanoc::Int::CompiledContentCache.new,
        checksum_store: checksum_store,
        rule_memory_store: rule_memory_store,
        rule_memory_calculator: rule_memory_calculator,
        dependency_store: dependency_store,
        outdatedness_checker: outdatedness_checker,
        reps: item_rep_repo,
      }

      compiler = Nanoc::Int::Compiler.new(site, rules_collection, params)

      Nanoc::Int::RulesLoader.new(site.config, rules_collection).load

      compiler
    end
  end
end
