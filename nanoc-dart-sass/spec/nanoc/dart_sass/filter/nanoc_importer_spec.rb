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
      items:,
      dependency_tracker:,
      compilation_context:,
      compiled_content_store:,
    )
  end

  let(:compilation_context) do
    Nanoc::Core::CompilationContext.new(
      action_provider:,
      reps:,
      site:,
      compiled_content_cache:,
      compiled_content_store:,
    )
  end

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }
  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
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
  let(:partial_item) { Nanoc::Core::Item.new('partial content here', {}, '/assets/style/_partial.scss') }
  let(:source_item) { screen_item }

  let(:items_array) do
    [
      screen_item,
      colors_item,
      partial_item,
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
    subject(:load_call) { importer.load(url) }

    context 'when importing absolute path with extension' do
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

    context 'when importing relative path with dot without extension' do
      let(:url) { './colors' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing relative path without dot with extension' do
      let(:url) { 'colors.scss' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing relative path without dot without extension' do
      let(:url) { 'colors' }

      it { is_expected.to eq({ contents: 'colors content here', syntax: :scss }) }
    end

    context 'when importing partial with relative path without dot with extension' do
      let(:url) { 'partial.scss' }

      it { is_expected.to eq({ contents: 'partial content here', syntax: :scss }) }
    end

    context 'when importing partial with relative path without dot without extension' do
      let(:url) { 'partial' }

      it { is_expected.to eq({ contents: 'partial content here', syntax: :scss }) }
    end

    context 'with index (not a partial)' do
      let(:foundation_item) { Nanoc::Core::Item.new('foundation/index content here', {}, '/assets/style/foundation/index.scss') }
      let(:source_item) { screen_item }

      let(:items_array) do
        [
          screen_item,
          foundation_item,
        ]
      end

      context 'when importing index with relative path without dot without extension' do
        let(:url) { 'foundation' }

        it { is_expected.to eq({ contents: 'foundation/index content here', syntax: :scss }) }
      end

      context 'when importing index with relative path with dot with extension' do
        let(:url) { 'foundation.*' }

        it 'raises' do
          expect { load_call }.to raise_error('Could not find an item matching pattern `/assets/style/foundation.*`')
        end
      end
    end

    context 'with index (partial)' do
      let(:foundation_item) { Nanoc::Core::Item.new('foundation/index content here', {}, '/assets/style/foundation/_index.scss') }
      let(:source_item) { screen_item }

      let(:items_array) do
        [
          screen_item,
          foundation_item,
        ]
      end

      context 'when importing index with relative path without dot without extension' do
        let(:url) { 'foundation' }

        it { is_expected.to eq({ contents: 'foundation/index content here', syntax: :scss }) }
      end

      context 'when importing index with relative path with dot with extension' do
        let(:url) { 'foundation.*' }

        it 'raises' do
          expect { load_call }.to raise_error('Could not find an item matching pattern `/assets/style/foundation.*`')
        end
      end
    end

    context 'with ambiguous import' do
      let(:color_scss_item) { Nanoc::Core::Item.new('foundation/index content here', {}, '/assets/style/color.scss') }
      let(:color_sass_item) { Nanoc::Core::Item.new('foundation/index content here', {}, '/assets/style/color.sass') }
      let(:source_item) { screen_item }

      let(:items_array) do
        [
          screen_item,
          color_scss_item,
          color_sass_item,
        ]
      end

      let(:url) { 'color.*' }

      it 'raises' do
        expect { load_call }.to raise_error('It is not clear which item to import. Multiple items match `/assets/style/color.*`: /assets/style/color.sass, /assets/style/color.scss')
      end
    end
  end
end
