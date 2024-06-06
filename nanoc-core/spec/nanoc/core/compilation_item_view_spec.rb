# frozen_string_literal: true

require_relative 'support/document_view_examples'

describe Nanoc::Core::CompilationItemView do
  let(:entity_class) { Nanoc::Core::Item }
  let(:other_view_class) { Nanoc::Core::LayoutView }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:empty_layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:empty_items) { Nanoc::Core::ItemCollection.new(config) }
  let(:base_item) { Nanoc::Core::Item.new('base', {}, '/base.md') }
  let(:dependency_store) { Nanoc::Core::DependencyStore.new(empty_items, empty_layouts, config) }
  let(:dependency_tracker) { Nanoc::Core::DependencyTracker.new(dependency_store) }
  let(:items) { Nanoc::Core::ItemCollection.new(config) }
  let(:layouts) { Nanoc::Core::LayoutCollection.new(config) }
  let(:reps) { Nanoc::Core::ItemRepRepo.new }

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

  it_behaves_like 'a document view'

  describe '#parent' do
    subject { view.parent }

    let(:item) do
      Nanoc::Core::Item.new('me', {}, identifier)
    end

    let(:view) { described_class.new(item, view_context) }

    let(:items) do
      Nanoc::Core::ItemCollection.new(
        {},
        [
          item,
          parent_item,
        ].compact,
      )
    end

    context 'with parent' do
      context 'full identifier' do
        let(:identifier) do
          Nanoc::Core::Identifier.new('/parent/me.md')
        end

        let(:parent_item) do
          Nanoc::Core::Item.new('parent', {}, '/parent.md')
        end

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Core::Errors::CannotGetParentOrChildrenOfNonLegacyItem)
        end
      end

      context 'legacy identifier' do
        let(:identifier) do
          Nanoc::Core::Identifier.new('/parent/me/', type: :legacy)
        end

        let(:parent_item) do
          Nanoc::Core::Item.new('parent', {}, Nanoc::Core::Identifier.new('/parent/', type: :legacy))
        end

        it 'returns a view for the parent' do
          expect(subject.class).to eql(described_class)
          expect(subject._unwrap).to eql(parent_item)
        end

        it 'returns a view with the right context' do
          expect(subject._context).to equal(view_context)
        end

        context 'frozen parent' do
          before { parent_item.freeze }

          it { is_expected.to be_frozen }
        end

        context 'non-frozen parent' do
          it { is_expected.not_to be_frozen }
        end

        context 'with root parent' do
          let(:parent_item) { Nanoc::Core::Item.new('parent', {}, parent_identifier) }
          let(:identifier) { Nanoc::Core::Identifier.new('/me/', type: :legacy) }
          let(:parent_identifier) { Nanoc::Core::Identifier.new('/', type: :legacy) }

          it 'returns a view for the parent' do
            expect(subject.class).to eql(described_class)
            expect(subject._unwrap).to eql(parent_item)
          end
        end
      end
    end

    context 'without parent' do
      let(:parent_item) do
        nil
      end

      context 'full identifier' do
        let(:identifier) do
          Nanoc::Core::Identifier.new('/me.md')
        end

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Core::Errors::CannotGetParentOrChildrenOfNonLegacyItem)
        end
      end

      context 'legacy identifier' do
        let(:identifier) do
          Nanoc::Core::Identifier.new('/me/', type: :legacy)
        end

        it { is_expected.to be_nil }
        it { is_expected.to be_frozen }
      end
    end
  end

  describe '#children' do
    subject { view.children }

    let(:item) do
      Nanoc::Core::Item.new('me', {}, identifier)
    end

    let(:view) { described_class.new(item, view_context) }

    let(:items) do
      Nanoc::Core::ItemCollection.new(
        {},
        [
          item,
          *children,
        ],
      )
    end

    context 'full identifier' do
      let(:identifier) do
        Nanoc::Core::Identifier.new('/me.md')
      end

      let(:children) do
        [Nanoc::Core::Item.new('child', {}, '/me/child.md')]
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Core::Errors::CannotGetParentOrChildrenOfNonLegacyItem)
      end
    end

    context 'legacy identifier' do
      let(:identifier) do
        Nanoc::Core::Identifier.new('/me/', type: :legacy)
      end

      let(:children) do
        [Nanoc::Core::Item.new('child', {}, Nanoc::Core::Identifier.new('/me/child/', type: :legacy))]
      end

      it 'returns views for the children' do
        expect(subject.size).to be(1)
        expect(subject[0].class).to eql(described_class)
        expect(subject[0]._unwrap).to eql(children[0])
      end

      it { is_expected.to be_frozen }
    end
  end

  describe '#reps' do
    subject { view.reps }

    let(:item) { Nanoc::Core::Item.new('blah', {}, '/foo.md') }
    let(:rep_a) { Nanoc::Core::ItemRep.new(item, :a) }
    let(:rep_b) { Nanoc::Core::ItemRep.new(item, :b) }

    let(:reps) do
      Nanoc::Core::ItemRepRepo.new.tap do |reps|
        reps << rep_a
        reps << rep_b
      end
    end

    let(:view) { described_class.new(item, view_context) }

    it 'returns a proper item rep collection' do
      expect(subject.size).to eq(2)
      expect(subject.class).to eql(Nanoc::Core::CompilationItemRepCollectionView)
    end

    it 'returns a view with the right context' do
      expect(subject._context).to eq(view_context)
    end
  end

  describe '#compiled_content' do
    subject { view.compiled_content(**params) }

    let(:view) { described_class.new(item, view_context) }

    let(:item) do
      Nanoc::Core::Item.new('content', {}, '/asdf')
    end

    let(:reps) do
      Nanoc::Core::ItemRepRepo.new.tap do |reps|
        reps << rep
      end
    end

    let(:rep) do
      Nanoc::Core::ItemRep.new(item, :default).tap do |ir|
        ir.compiled = true
        ir.snapshot_defs = [
          Nanoc::Core::SnapshotDef.new(:last, binary: false),
          Nanoc::Core::SnapshotDef.new(:pre, binary: false),
          Nanoc::Core::SnapshotDef.new(:post, binary: false),
          Nanoc::Core::SnapshotDef.new(:specific, binary: false),
        ]
      end
    end

    before do
      compiled_content_store.set(rep, :last, Nanoc::Core::TextualContent.new('Last Hallo'))
      compiled_content_store.set(rep, :pre, Nanoc::Core::TextualContent.new('Pre Hallo'))
      compiled_content_store.set(rep, :post, Nanoc::Core::TextualContent.new('Post Hallo'))
      compiled_content_store.set(rep, :specific, Nanoc::Core::TextualContent.new('Specific Hallo'))
    end

    context 'requesting implicit default rep' do
      let(:params) { {} }

      it { is_expected.to eq('Pre Hallo') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
      end

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('Specific Hallo') }

        it 'creates a dependency' do
          expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
        end
      end
    end

    context 'requesting explicit default rep' do
      let(:params) { { rep: :default } }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
      end

      it { is_expected.to eq('Pre Hallo') }

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('Specific Hallo') }
      end
    end

    context 'requesting other rep' do
      let(:params) { { rep: :other } }

      it 'raises an error' do
        expect { subject }.to raise_error(Nanoc::Core::BasicItemRepCollectionView::NoSuchItemRepError)
      end
    end
  end

  describe '#path' do
    subject { view.path(**params) }

    let(:view) { described_class.new(item, view_context) }

    let(:item) do
      Nanoc::Core::Item.new('content', {}, '/asdf.md')
    end

    let(:reps) do
      Nanoc::Core::ItemRepRepo.new.tap do |reps|
        reps << rep
      end
    end

    let(:rep) do
      Nanoc::Core::ItemRep.new(item, :default).tap do |ir|
        ir.paths = {
          last: ['/about/'],
          specific: ['/about.txt'],
        }
      end
    end

    context 'requesting implicit default rep' do
      let(:params) { {} }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
      end

      it { is_expected.to eq('/about/') }

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('/about.txt') }
      end
    end

    context 'requesting explicit default rep' do
      let(:params) { { rep: :default } }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
      end

      it { is_expected.to eq('/about/') }

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('/about.txt') }
      end
    end

    context 'requesting other rep' do
      let(:params) { { rep: :other } }

      it 'raises an error' do
        expect { subject }.to raise_error(Nanoc::Core::BasicItemRepCollectionView::NoSuchItemRepError)
      end
    end
  end

  describe '#binary?' do
    # TODO: implement
  end

  describe '#raw_filename' do
    subject { view.raw_filename }

    let(:item) do
      Nanoc::Core::Item.new(content, { animal: 'donkey' }, '/foo')
    end

    let(:view) { described_class.new(item, view_context) }

    context 'textual content with no raw filename' do
      let(:content) { Nanoc::Core::TextualContent.new('asdf') }

      it { is_expected.to be_nil }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
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

    context 'textual content with raw filename' do
      let(:content) { Nanoc::Core::TextualContent.new('asdf', filename:) }
      let(:filename) { '/tmp/lol.txt' }

      it { is_expected.to eql('/tmp/lol.txt') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
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

    context 'binary content' do
      let(:content) { Nanoc::Core::BinaryContent.new(filename) }
      let(:filename) { '/tmp/lol.txt' }

      it { is_expected.to eql('/tmp/lol.txt') }

      it 'creates a dependency' do
        expect { subject }.to change { dependency_store.objects_causing_outdatedness_of(base_item) }.from([]).to([item])
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

  describe '#inspect' do
    subject { view.inspect }

    let(:item) { Nanoc::Core::Item.new('content', {}, '/asdf') }
    let(:view) { described_class.new(item, nil) }

    it { is_expected.to eql('<Nanoc::Core::CompilationItemView identifier=/asdf>') }
  end
end
