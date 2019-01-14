# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    class CompilerLoader
      def load(site, action_provider: nil)
        action_sequence_store = Nanoc::Int::ActionSequenceStore.new(config: site.config)

        dependency_store =
          Nanoc::Int::DependencyStore.new(site.items, site.layouts, site.config)

        objects = site.items.to_a + site.layouts.to_a + site.code_snippets + [site.config]

        checksum_store =
          Nanoc::Int::ChecksumStore.new(config: site.config, objects: objects)

        action_provider ||= Nanoc::Int::ActionProvider.named(site.config.action_provider).for(site)

        outdatedness_store =
          Nanoc::Int::OutdatednessStore.new(config: site.config)

        compiled_content_cache =
          Nanoc::Int::CompositeCache.new(config: site.config)

        params = {
          compiled_content_cache: compiled_content_cache,
          checksum_store: checksum_store,
          action_sequence_store: action_sequence_store,
          dependency_store: dependency_store,
          action_provider: action_provider,
          outdatedness_store: outdatedness_store,
        }

        Nanoc::Int::Compiler.new(site, params)
      end
    end
  end
end
