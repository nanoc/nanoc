module Nanoc::Int
  # @api private
  class CompilerLoader
    def load(site, action_provider: nil)
      rule_memory_store = Nanoc::Int::RuleMemoryStore.new(env_name: site.config.env_name)

      dependency_store =
        Nanoc::Int::DependencyStore.new(site.items.to_a + site.layouts.to_a, env_name: site.config.env_name)

      checksum_store =
        Nanoc::Int::ChecksumStore.new(site: site)

      item_rep_repo = Nanoc::Int::ItemRepRepo.new

      action_provider ||= Nanoc::Int::ActionProvider.named(:rule_dsl).for(site)

      outdatedness_checker =
        Nanoc::Int::OutdatednessChecker.new(
          site: site,
          checksum_store: checksum_store,
          dependency_store: dependency_store,
          rule_memory_store: rule_memory_store,
          action_provider: action_provider,
          reps: item_rep_repo,
        )

      compiled_content_cache =
        Nanoc::Int::CompiledContentCache.new(
          env_name: site.config.env_name,
          items: site.items,
        )

      params = {
        compiled_content_cache: compiled_content_cache,
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
