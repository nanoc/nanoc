# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class CompilerLoader
      def load(site, focus: nil, action_provider: nil)
        action_sequence_store = Nanoc::Core::ActionSequenceStore.new(config: site.config)

        dependency_store =
          Nanoc::Core::DependencyStore.new(site.items, site.layouts, site.config)

        objects = site.items.to_a + site.layouts.to_a + site.code_snippets + [site.config]

        checksum_store =
          Nanoc::Core::ChecksumStore.new(config: site.config, objects:)

        action_provider ||= Nanoc::Core::ActionProvider.named(site.config.action_provider).for(site)

        outdatedness_store =
          Nanoc::Core::OutdatednessStore.new(config: site.config)

        compiled_content_cache =
          compiled_content_cache_class.new(config: site.config)

        params = {
          compiled_content_cache:,
          checksum_store:,
          action_sequence_store:,
          dependency_store:,
          action_provider:,
          outdatedness_store:,
          focus:,
        }

        Nanoc::Core::Compiler.new(site, **params)
      end

      def compiled_content_cache_class
        Nanoc::Core::CompiledContentCache
      end
    end
  end
end
