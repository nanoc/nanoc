# frozen_string_literal: true

shared_examples 'a document view' do
  let(:view) { described_class.new(document, view_context) }

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(dependency_store) }
  let(:dependency_store) { Nanoc::Core::DependencyStore.new(items, layouts, config) }
  let(:base_item) { Nanoc::Core::Item.new('base', {}, '/base.md') }

  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: Nanoc::Core::ItemCollection.new(config),
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

      def initialize; end
    end.new
  end

  before do
    dependency_tracker.enter(base_item)
  end

  describe '#frozen?' do
    subject { view.frozen? }

    let(:document) { entity_class.new('content', {}, '/asdf') }

    context 'non-frozen document' do
      it { is_expected.to be(false) }
    end

    context 'frozen document' do
      before { document.freeze }

      it { is_expected.to be(true) }
    end
  end

  describe '#== and #eql?' do
    let(:document) { entity_class.new('content', {}, '/asdf') }

    context 'comparing with document with same identifier' do
      let(:other) { entity_class.new('content', {}, '/asdf') }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document with different identifier' do
      let(:other) { entity_class.new('content', {}, '/fdsa') }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document view with same identifier' do
      let(:other) { other_view_class.new(entity_class.new('content', {}, '/asdf'), nil) }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document view with different identifier' do
      let(:other) { other_view_class.new(entity_class.new('content', {}, '/fdsa'), nil) }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with other object' do
      let(:other) { nil }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#[]' do
    subject { view[key] }

    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo') }

    context 'with existant key' do
      let(:key) { :animal }

      it { is_expected.to eql('donkey') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.compiled_content?).to be(false)
        expect(dep.props.path?).to be(false)
      end
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      it { is_expected.to be_nil }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.compiled_content?).to be(false)
        expect(dep.props.path?).to be(false)
      end
    end
  end

  describe '#attributes' do
    subject { view.attributes }

    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo') }

    it 'creates a dependency' do
      expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
    end

    it 'creates a dependency with the right props' do
      subject
      dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

      expect(dep.props.attributes?).to be(true)

      expect(dep.props.raw_content?).to be(false)
      expect(dep.props.compiled_content?).to be(false)
      expect(dep.props.path?).to be(false)
    end

    it 'returns attributes' do
      expect(subject).to eql(animal: 'donkey')
    end
  end

  describe '#fetch' do
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo') }

    context 'with existant key' do
      subject { view.fetch(key) }

      let(:key) { :animal }

      it { is_expected.to eql('donkey') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.compiled_content?).to be(false)
        expect(dep.props.path?).to be(false)
      end
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      context 'with fallback' do
        subject { view.fetch(key, 'nothing sorry') }

        it { is_expected.to eql('nothing sorry') }

        it 'creates a dependency' do
          expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
        end

        it 'creates a dependency with the right props' do
          subject
          dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

          expect(dep.props.attributes?).to be(true)

          expect(dep.props.raw_content?).to be(false)
          expect(dep.props.compiled_content?).to be(false)
          expect(dep.props.path?).to be(false)
        end
      end

      context 'with block' do
        subject { view.fetch(key) { 'nothing sorry' } } # rubocop:disable Style/RedundantFetchBlock

        it { is_expected.to eql('nothing sorry') }

        it 'creates a dependency' do
          expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
        end

        it 'creates a dependency with the right props' do
          subject
          dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

          expect(dep.props.attributes?).to be(true)

          expect(dep.props.raw_content?).to be(false)
          expect(dep.props.compiled_content?).to be(false)
          expect(dep.props.path?).to be(false)
        end
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

    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo') }

    context 'with existant key' do
      let(:key) { :animal }

      it { is_expected.to be(true) }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.compiled_content?).to be(false)
        expect(dep.props.path?).to be(false)
      end
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      it { is_expected.to be(false) }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.compiled_content?).to be(false)
        expect(dep.props.path?).to be(false)
      end
    end
  end

  describe '#hash' do
    subject { view.hash }

    let(:document) { double(:document, identifier: '/foo') }

    it { is_expected.to eq([described_class, '/foo'].hash) }
  end

  describe '#raw_content' do
    subject { view.raw_content }

    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo') }

    it { is_expected.to eql('stuff') }

    it 'creates a dependency' do
      expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
    end

    it 'creates a dependency with the right props' do
      subject
      dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

      expect(dep.props.raw_content?).to be(true)

      expect(dep.props.attributes?).to be(false)
      expect(dep.props.compiled_content?).to be(false)
      expect(dep.props.path?).to be(false)
    end
  end
end
