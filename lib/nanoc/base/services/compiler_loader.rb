module Nanoc::Int
  # @api private
  class CompilerLoader
    def load(site)
      rules_collection = Nanoc::Int::RulesCollection.new

      rule_memory_store = Nanoc::Int::RuleMemoryStore.new
      rule_memory_calculator = Nanoc::Int::RuleMemoryCalculator.new(
        rules_collection: rules_collection,
        site: site,
      )

      params = {
        compiled_content_cache: Nanoc::Int::CompiledContentCache.new,
        checksum_store: Nanoc::Int::ChecksumStore.new(site: site),
        rule_memory_store: rule_memory_store,
        rule_memory_calculator: rule_memory_calculator,
      }

      compiler = Nanoc::Int::Compiler.new(site, rules_collection, params)

      Nanoc::Int::RulesLoader.new(site.config, rules_collection).load

      compiler
    end
  end
end
