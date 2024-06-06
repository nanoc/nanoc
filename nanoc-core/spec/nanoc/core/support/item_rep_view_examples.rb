# frozen_string_literal: true

shared_examples 'an item rep view' do
  # needs expected_item_view_class

  let(:view_context) do
    Nanoc::Core::ViewContextForCompilation.new(
      reps:,
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

  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

  let(:compiled_content_store) { Nanoc::Core::CompiledContentStore.new }
  let(:compiled_content_cache) { Nanoc::Core::CompiledContentCache.new(config:) }

  let(:action_provider) do
    Class.new(Nanoc::Core::ActionProvider) do
      def self.for(_context)
        raise NotImplementedError
      end

      def initialize; end
    end.new
  end

  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(dependency_store) }
  let(:dependency_store) { Nanoc::Core::DependencyStore.new(empty_items, empty_layouts, config) }
  let(:base_item) { Nanoc::Core::Item.new('base', {}, '/base.md') }

  let(:empty_items) { Nanoc::Core::ItemCollection.new(config) }
  let(:empty_layouts) { Nanoc::Core::LayoutCollection.new(config) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets: [],
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  before do
    dependency_tracker.enter(base_item)
  end

  describe '#frozen?' do
    subject { view.frozen? }

    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
    let(:view) { described_class.new(item_rep, view_context) }

    context 'non-frozen item rep' do
      it { is_expected.to be(false) }
    end

    context 'frozen item rep' do
      before { item_rep.freeze }

      it { is_expected.to be(true) }
    end
  end

  describe '#== and #eql?' do
    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
    let(:view) { described_class.new(item_rep, view_context) }

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo') }
      let(:other) { double(:other_item_rep, item: other_item, name: :marvin) }

      it 'is not ==' do
        expect(view).not_to eq(other)
      end

      it 'is not eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques), view_context) }

      it 'is ==' do
        expect(view).to eq(other)
      end

      it 'is eql?' do
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques), view_context) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :marvin), view_context) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with something that is not an item rep' do
      let(:other_item) { double(:other_item, identifier: '/foo') }
      let(:other) { :donkey }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#hash' do
    subject { view.hash }

    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
    let(:view) { described_class.new(item_rep, view_context) }

    it { is_expected.to eq([described_class, Nanoc::Core::Identifier.new('/foo'), :jacques].hash) }
  end

  describe '#snapshot?' do
    subject { view.snapshot?(snapshot_name) }

    let(:view) { described_class.new(rep, view_context) }

    let(:rep) do
      Nanoc::Core::ItemRep.new(item, :default).tap do |ir|
        ir.compiled = true
        ir.snapshot_defs = [
          Nanoc::Core::SnapshotDef.new(:last, binary: false),
        ]
      end
    end

    let(:item) do
      Nanoc::Core::Item.new('content', {}, '/asdf.md')
    end

    let(:snapshot_name) { raise 'override me' }

    before do
      compiled_content_store.set(rep, :last, Nanoc::Core::TextualContent.new('Hallo'))
    end

    context 'snapshot exists' do
      let(:snapshot_name) { :last }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.compiled_content?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.attributes?).to be(false)
        expect(dep.props.path?).to be(false)
      end

      it { is_expected.not_to be(false) }
    end

    context 'snapshot does not exist' do
      let(:snapshot_name) { :donkey }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
      end

      it 'creates a dependency with the right props' do
        subject
        dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

        expect(dep.props.compiled_content?).to be(true)

        expect(dep.props.raw_content?).to be(false)
        expect(dep.props.attributes?).to be(false)
        expect(dep.props.path?).to be(false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#path' do
    subject { view.path }

    let(:view) { described_class.new(rep, view_context) }

    let(:rep) do
      Nanoc::Core::ItemRep.new(item, :default).tap do |ir|
        ir.paths = {
          last: ['/about/'],
        }
      end
    end

    let(:item) do
      Nanoc::Core::Item.new('content', {}, '/asdf.md')
    end

    it 'creates a dependency' do
      expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
    end

    it 'creates a dependency with the right props' do
      subject
      dep = dependency_store.dependencies_causing_outdatedness_of(base_item)[0]

      expect(dep.props.path?).to be(true)

      expect(dep.props.raw_content?).to be(false)
      expect(dep.props.attributes?).to be(false)
      expect(dep.props.compiled_content?).to be(false)
    end

    it { is_expected.to eq('/about/') }
  end

  describe '#binary?' do
    subject { view.binary? }

    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
    let(:view) { described_class.new(item_rep, view_context) }

    context 'no :last snapshot' do
      before do
        item_rep.snapshot_defs = []
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Core::Errors::NoSuchSnapshot)
      end
    end

    context ':last snapshot is textual' do
      before do
        item_rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: false)]
      end

      it { is_expected.to be(false) }
    end

    context ':last snapshot is binary' do
      before do
        item_rep.snapshot_defs = [Nanoc::Core::SnapshotDef.new(:last, binary: true)]
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#item' do
    subject { view.item }

    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
    let(:view) { described_class.new(item_rep, view_context) }

    it 'returns an item view' do
      expect(subject).to be_a(expected_item_view_class)
    end

    it 'returns an item view with the right context' do
      expect(subject._context).to equal(view_context)
    end
  end

  describe '#inspect' do
    subject { view.inspect }

    let(:item_rep) { Nanoc::Core::ItemRep.new(item, :jacques) }
    let(:item) { Nanoc::Core::Item.new('asdf', {}, '/foo') }
    let(:view) { described_class.new(item_rep, view_context) }

    it { is_expected.to eql('<' + described_class.to_s + ' item.identifier=/foo name=jacques>') }
  end
end
