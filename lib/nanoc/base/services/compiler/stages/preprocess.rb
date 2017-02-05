module Nanoc::Int::Compiler::Stages
  class Preprocess
    def initialize(action_provider:, site:, dependency_store:, checksum_store:)
      @action_provider = action_provider
      @site = site
      @dependency_store = dependency_store
      @checksum_store = checksum_store
    end

    def run
      @site.data_source = Nanoc::Int::InMemDataSource.new(@site.items, @site.layouts)
      @action_provider.preprocess(@site)

      @dependency_store.objects = @site.items.to_a + @site.layouts.to_a
      @checksum_store.objects = @site.items.to_a + @site.layouts.to_a + @site.code_snippets + [@site.config]

      @site.freeze
    end
  end
end
