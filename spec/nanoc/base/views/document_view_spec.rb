# frozen_string_literal: true

shared_examples 'a document view' do
  let(:view) { described_class.new(document, view_context) }

  let(:view_context) do
    Nanoc::ViewContext.new(
      reps: double(:reps),
      items: double(:items),
      dependency_tracker: dependency_tracker,
      compilation_context: double(:compilation_context),
      snapshot_repo: double(:snapshot_repo),
    )
  end

  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(dependency_store) }
  let(:dependency_store) { Nanoc::Int::DependencyStore.new(empty_identifiable_collection, empty_identifiable_collection, config) }
  let(:base_item) { Nanoc::Int::Item.new('base', {}, '/base.md') }

  let(:empty_identifiable_collection) do
    Nanoc::Int::IdentifiableCollection.new(config)
  end

  let(:config) { Nanoc::Int::Configuration.new.with_defaults }

  before do
    dependency_tracker.enter(base_item)
  end

  describe '#frozen?' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    subject { view.frozen? }

    context 'non-frozen document' do
      it { is_expected.to be(false) }
    end

    context 'frozen document' do
      before { document.freeze }
      it { is_expected.to be(true) }
    end
  end

  describe '#== and #eql?' do
    let(:document) { entity_class.new('content', {}, '/asdf/') }

    context 'comparing with document with same identifier' do
      let(:other) { entity_class.new('content', {}, '/asdf/') }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document with different identifier' do
      let(:other) { entity_class.new('content', {}, '/fdsa/') }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document view with same identifier' do
      let(:other) { other_view_class.new(entity_class.new('content', {}, '/asdf/'), nil) }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with document view with different identifier' do
      let(:other) { other_view_class.new(entity_class.new('content', {}, '/fdsa/'), nil) }

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
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    subject { view[key] }

    context 'with existant key' do
      let(:key) { :animal }

      it { is_expected.to eql('donkey') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.compiled_content?).to eq(false)
        expect(dep.props.path?).to eq(false)
      end
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      it { is_expected.to eql(nil) }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.compiled_content?).to eq(false)
        expect(dep.props.path?).to eq(false)
      end
    end
  end

  describe '#attributes' do
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    subject { view.attributes }

    it 'creates a dependency' do
      expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
    end

    it 'creates a dependency with the right props' do
      subject
      dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

      expect(dep.props.attributes?).to eq(true)

      expect(dep.props.raw_content?).to eq(false)
      expect(dep.props.compiled_content?).to eq(false)
      expect(dep.props.path?).to eq(false)
    end

    it 'returns attributes' do
      expect(subject).to eql(animal: 'donkey')
    end
  end

  describe '#fetch' do
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    context 'with existant key' do
      let(:key) { :animal }

      subject { view.fetch(key) }

      it { is_expected.to eql('donkey') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.compiled_content?).to eq(false)
        expect(dep.props.path?).to eq(false)
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

          expect(dep.props.attributes?).to eq(true)

          expect(dep.props.raw_content?).to eq(false)
          expect(dep.props.compiled_content?).to eq(false)
          expect(dep.props.path?).to eq(false)
        end
      end

      context 'with block' do
        subject { view.fetch(key) { 'nothing sorry' } }

        it { is_expected.to eql('nothing sorry') }

        it 'creates a dependency' do
          expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
        end

        it 'creates a dependency with the right props' do
          subject
          dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

          expect(dep.props.attributes?).to eq(true)

          expect(dep.props.raw_content?).to eq(false)
          expect(dep.props.compiled_content?).to eq(false)
          expect(dep.props.path?).to eq(false)
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
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    subject { view.key?(key) }

    context 'with existant key' do
      let(:key) { :animal }

      it { is_expected.to eql(true) }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.compiled_content?).to eq(false)
        expect(dep.props.path?).to eq(false)
      end
    end

    context 'with non-existant key' do
      let(:key) { :weapon }

      it { is_expected.to eql(false) }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.attributes?).to eq(true)

        expect(dep.props.raw_content?).to eq(false)
        expect(dep.props.compiled_content?).to eq(false)
        expect(dep.props.path?).to eq(false)
      end
    end
  end

  describe '#hash' do
    let(:document) { double(:document, identifier: '/foo/') }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end

  describe '#raw_content' do
    let(:document) { entity_class.new('stuff', { animal: 'donkey' }, '/foo/') }

    subject { view.raw_content }

    it { is_expected.to eql('stuff') }

    it 'creates a dependency' do
      expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([document])
    end

    it 'creates a dependency with the right props' do
      subject
      dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

      expect(dep.props.raw_content?).to eq(true)

      expect(dep.props.attributes?).to eq(false)
      expect(dep.props.compiled_content?).to eq(false)
      expect(dep.props.path?).to eq(false)
    end
  end
end
