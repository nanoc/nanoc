# frozen_string_literal: true

describe Nanoc::Core::ConfigView do
  let(:config) do
    Nanoc::Core::Configuration.new(dir: Dir.getwd, hash:)
  end

  let(:hash) { { output_dir: 'ootpoot/', amount: 9000, animal: 'donkey', foo: { bar: :baz } } }

  let(:view) { described_class.new(config, view_context) }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker:,
      compilation_context:,
      compiled_content_store:,
    )
  end

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker::Null.new }

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

  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  describe '#frozen?' do
    subject { view.frozen? }

    context 'non-frozen config' do
      it { is_expected.to be(false) }
    end

    context 'frozen config' do
      before { config.freeze }

      it { is_expected.to be(true) }
    end
  end

  describe '#[]' do
    subject { view[key] }

    before do
      expect(dependency_tracker).to receive(:bounce).with(config, attributes: [key])
    end

    context 'with existing key' do
      let(:key) { :animal }

      it { is_expected.to eql('donkey') }
    end

    context 'with non-existing key' do
      let(:key) { :weapon }

      it { is_expected.to be_nil }
    end
  end

  describe '#fetch' do
    before do
      expect(dependency_tracker).to receive(:bounce).with(config, attributes: [key])
    end

    context 'with existing key' do
      subject { view.fetch(key) }

      let(:key) { :animal }

      it { is_expected.to eql('donkey') }
    end

    context 'with non-existing key' do
      let(:key) { :weapon }

      context 'with fallback' do
        subject { view.fetch(key, 'nothing sorry') }

        it { is_expected.to eql('nothing sorry') }
      end

      context 'with block' do
        subject { view.fetch(key) { 'nothing sorry' } } # rubocop:disable Style/RedundantFetchBlock

        it { is_expected.to eql('nothing sorry') }
      end

      context 'with no fallback and no block' do
        subject { view.fetch(key) }

        it 'raises' do
          expect { subject }.to raise_error(KeyError)
        end
      end
    end
  end

  describe '#key?' do
    subject { view.key?(key) }

    before do
      expect(dependency_tracker).to receive(:bounce).with(config, attributes: [key])
    end

    context 'with existing key' do
      let(:key) { :animal }

      it { is_expected.to be(true) }
    end

    context 'with non-existing key' do
      let(:key) { :weapon }

      it { is_expected.to be(false) }
    end
  end

  describe '#env_name' do
    subject { view.env_name }

    before do
      expect(dependency_tracker).to receive(:bounce).with(config, attributes: true)
    end

    context 'when configuration is constructed with an env_name' do
      let(:config) do
        Nanoc::Core::Configuration.new(dir: Dir.getwd, hash:, env_name: 'produx10n')
      end

      it { is_expected.to eql('produx10n') }
    end

    context 'when configuration is not constructed with an env_name' do
      let(:config) do
        Nanoc::Core::Configuration.new(dir: Dir.getwd, hash:)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#each' do
    before do
      expect(dependency_tracker).to receive(:bounce).with(config, attributes: true)
    end

    example do
      res = []
      view.each { |k, v| res << [k, v] }

      expect(res).to eql([[:output_dir, 'ootpoot/'], [:amount, 9000], [:animal, 'donkey'], [:foo, { bar: :baz }]])
    end
  end

  describe '#dig' do
    subject { view.dig(*keys) }

    before do
      expect(dependency_tracker).to receive(:bounce).with(config, attributes: [:foo])
    end

    context 'with existing keys' do
      let(:keys) { %i[foo bar] }

      it { is_expected.to be(:baz) }
    end

    context 'with non-existing keys' do
      let(:keys) { %i[foo baz bar] }

      it { is_expected.to be_nil }
    end
  end

  describe '#inspect' do
    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::Core::ConfigView>') }
  end
end
