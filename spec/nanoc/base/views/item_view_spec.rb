describe Nanoc::ItemWithRepsView do
  let(:entity_class) { Nanoc::Int::Item }
  let(:other_view_class) { Nanoc::LayoutView }
  it_behaves_like 'a document view'

  let(:view_context) do
    Nanoc::ViewContext.new(
      reps: reps,
      items: items,
      dependency_tracker: dependency_tracker,
      compilation_context: compilation_context,
      snapshot_repo: snapshot_repo,
    )
  end

  let(:reps) { [] }
  let(:items) { [] }
  let(:dependency_tracker) { Nanoc::Int::DependencyTracker.new(dependency_store) }
  let(:dependency_store) { Nanoc::Int::DependencyStore.new(empty_identifiable_collection, empty_identifiable_collection) }
  let(:compilation_context) { double(:compilation_context) }
  let(:snapshot_repo) { Nanoc::Int::SnapshotRepo.new }

  let(:base_item) { Nanoc::Int::Item.new('base', {}, '/base.md') }

  let(:empty_identifiable_collection) do
    Nanoc::Int::IdentifiableCollection.new(config)
  end

  let(:config) { Nanoc::Int::Configuration.new.with_defaults }

  before do
    dependency_tracker.enter(base_item)
  end

  describe '#parent' do
    let(:item) do
      Nanoc::Int::Item.new('me', {}, identifier)
    end

    let(:view) { described_class.new(item, view_context) }

    let(:items) do
      Nanoc::Int::IdentifiableCollection.new(
        {},
        [
          item,
          parent_item,
        ].compact,
      )
    end

    subject { view.parent }

    context 'with parent' do
      let(:parent_item) do
        Nanoc::Int::Item.new('parent', {}, '/parent/')
      end

      context 'full identifier' do
        let(:identifier) do
          Nanoc::Identifier.new('/parent/me.md')
        end

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetParentOrChildrenOfNonLegacyItem)
        end
      end

      context 'legacy identifier' do
        let(:identifier) do
          Nanoc::Identifier.new('/parent/me/', type: :legacy)
        end

        it 'returns a view for the parent' do
          expect(subject.class).to eql(Nanoc::ItemWithRepsView)
          expect(subject.unwrap).to eql(parent_item)
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
          let(:parent_item) { Nanoc::Int::Item.new('parent', {}, '/') }
          let(:identifier) { Nanoc::Identifier.new('/me/', type: :legacy) }

          it 'returns a view for the parent' do
            expect(subject.class).to eql(Nanoc::ItemWithRepsView)
            expect(subject.unwrap).to eql(parent_item)
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
          Nanoc::Identifier.new('/me.md')
        end

        it 'raises' do
          expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetParentOrChildrenOfNonLegacyItem)
        end
      end

      context 'legacy identifier' do
        let(:identifier) do
          Nanoc::Identifier.new('/me/', type: :legacy)
        end

        it { is_expected.to be_nil }
        it { is_expected.to be_frozen }
      end
    end
  end

  describe '#children' do
    let(:item) do
      Nanoc::Int::Item.new('me', {}, identifier)
    end

    let(:children) do
      [Nanoc::Int::Item.new('child', {}, '/me/child/')]
    end

    let(:view) { described_class.new(item, view_context) }

    let(:items) do
      Nanoc::Int::IdentifiableCollection.new(
        {},
        [
          item,
          *children,
        ],
      )
    end

    subject { view.children }

    context 'full identifier' do
      let(:identifier) do
        Nanoc::Identifier.new('/me.md')
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::CannotGetParentOrChildrenOfNonLegacyItem)
      end
    end

    context 'legacy identifier' do
      let(:identifier) do
        Nanoc::Identifier.new('/me/', type: :legacy)
      end

      it 'returns views for the children' do
        expect(subject.size).to eql(1)
        expect(subject[0].class).to eql(Nanoc::ItemWithRepsView)
        expect(subject[0].unwrap).to eql(children[0])
      end

      it { is_expected.to be_frozen }
    end
  end

  describe '#reps' do
    let(:item) { Nanoc::Int::Item.new('blah', {}, '/foo.md') }
    let(:rep_a) { Nanoc::Int::ItemRep.new(item, :a) }
    let(:rep_b) { Nanoc::Int::ItemRep.new(item, :b) }

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        reps << rep_a
        reps << rep_b
      end
    end

    let(:view) { described_class.new(item, view_context) }

    subject { view.reps }

    it 'returns a proper item rep collection' do
      expect(subject.size).to eq(2)
      expect(subject.class).to eql(Nanoc::ItemRepCollectionView)
    end

    it 'returns a view with the right context' do
      expect(subject._context).to eq(view_context)
    end
  end

  describe '#compiled_content' do
    subject { view.compiled_content(params) }

    let(:view) { described_class.new(item, view_context) }

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf/')
    end

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        reps << rep
      end
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.compiled = true
        ir.snapshot_defs = [
          Nanoc::Int::SnapshotDef.new(:last, binary: false),
          Nanoc::Int::SnapshotDef.new(:pre, binary: false),
          Nanoc::Int::SnapshotDef.new(:post, binary: false),
          Nanoc::Int::SnapshotDef.new(:specific, binary: false),
        ]
      end
    end

    before do
      snapshot_repo.set(rep, :last, Nanoc::Int::TextualContent.new('Last Hallo'))
      snapshot_repo.set(rep, :pre, Nanoc::Int::TextualContent.new('Pre Hallo'))
      snapshot_repo.set(rep, :post, Nanoc::Int::TextualContent.new('Post Hallo'))
      snapshot_repo.set(rep, :specific, Nanoc::Int::TextualContent.new('Specific Hallo'))
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
        expect { subject }.to raise_error(Nanoc::ItemRepCollectionView::NoSuchItemRepError)
      end
    end
  end

  describe '#path' do
    subject { view.path(params) }

    let(:view) { described_class.new(item, view_context) }

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf.md')
    end

    let(:reps) do
      Nanoc::Int::ItemRepRepo.new.tap do |reps|
        reps << rep
      end
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
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
        expect { subject }.to raise_error(Nanoc::ItemRepCollectionView::NoSuchItemRepError)
      end
    end
  end

  describe '#binary?' do
    # TODO: implement
  end

  describe '#raw_filename' do
    # TODO: implement
  end

  describe '#inspect' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::ItemWithRepsView identifier=/asdf/>') }
  end
end
