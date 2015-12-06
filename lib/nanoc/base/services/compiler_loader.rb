module Nanoc::Int
  # @api private
  class CompilerLoader
    def load(site)
      rule_memory_store = Nanoc::Int::RuleMemoryStore.new

      dependency_store =
        Nanoc::Int::DependencyStore.new(site.items.to_a + site.layouts.to_a)

      checksum_store =
        Nanoc::Int::ChecksumStore.new(site: site)

      item_rep_repo = Nanoc::Int::ItemRepRepo.new

      action_provider = Nanoc::RuleDSL::ActionProvider.for(site)

      outdatedness_checker =
        Nanoc::Int::OutdatednessChecker.new(
          site: site,
          checksum_store: checksum_store,
          dependency_store: dependency_store,
          rule_memory_store: rule_memory_store,
          action_provider: action_provider,
          reps: item_rep_repo,
        )

      params = {
        compiled_content_cache: Nanoc::Int::CompiledContentCache.new,
        checksum_store: checksum_store,
        rule_memory_store: rule_memory_store,
        dependency_store: dependency_store,
        outdatedness_checker: outdatedness_checker,
        reps: item_rep_repo,
        action_provider: action_provider,
      }

      Nanoc::Int::Compiler.new(site, params)
    end
  end
end
