# frozen_string_literal: true

describe Nanoc::DartSass::Filter::NanocImporter do
  let(:importer) { described_class.new(items_view, source_item) }

  let(:items_view) { Nanoc::Core::ItemCollectionWithoutRepsView.new(items, view_context) }
  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:base_item) { Nanoc::Core::Item.new('base', {}, '/base.md') }
  let(:dependency_store) { Nanoc::Core::DependencyStore.new(items, layouts, config) }
  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(dependency_store) }

  let(:items) { Nanoc::Core::ItemCollection.new(config, items_array) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: items,
      dependency_tracker: dependency_tracker,
      compilation_context: compilation_context,
      compiled_content_store: compiled_content_store,
    )
  end

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider: action_provider,
      reps: reps,
      site: site,
      compiled_content_cache: compiled_content_cache,
      compiled_content_store: compiled_content_store,
    )
  end

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }
  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config: config) }

  let(:site) do
    Nanoc::Core::Site.new(
      config: config,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end
    end.new
  end

  let(:screen_item) { Nanoc::Core::Item.new('screen content here', {}, '/assets/style/screen.scss') }
  let(:colors_item) { Nanoc::Core::Item.new('colors content here', {}, '/assets/style/colors.scss') }
  let(:fonts_item) { Nanoc::Core::Item.new('fonts content here', {}, '/assets/fonts.scss') }
  let(:source_item) { screen_item }

  let(:items_array) do
    [
      screen_item,
      colors_item,
      fonts_item,
    ]
  end

  describe '#canonicalize' do
    subject { importer.canonicalize(url) }

    context 'when given a URL with nanoc: prefix' do
      let(:url) { 'nanoc:foo' }

      it { is_expected.to eq('nanoc:foo') }
    end

    context 'when given a URL without nanoc: prefix' do
      let(:url) { 'foo' }

      it { is_expected.to eq('nanoc:foo') }
    end
  end

  describe '#load' do
    subject { importer.load(url) }

    context 'when importing absolute, full path' do
      let(:url) { '/assets/style/colors.scss' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing absolute path without extension' do
      let(:url) { '/assets/style/colors' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing relative path with dot with extension' do
      let(:url) { './colors.scss' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing absolute path with dot without extension' do
      let(:url) { './colors' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing relative path without dot with extension' do
      let(:url) { 'colors.scss' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing absolute path without dot without extension' do
      let(:url) { 'colors' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end
  end
end
