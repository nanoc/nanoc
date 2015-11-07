describe Nanoc::ItemView do
  let(:entity_class) { Nanoc::Int::Item }
  it_behaves_like 'a document view'

  describe '#raw_content' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

    subject { view.raw_content }

    it { should eq('content') }
  end

  describe '#parent' do
    let(:item) do
      Nanoc::Int::Item.new('me', {}, identifier).tap { |i| i.parent = parent_item }
    end

    let(:view) { described_class.new(item, view_context) }

    let(:view_context) { double(:view_context) }

    subject { view.parent }

    context 'with parent' do
      let(:parent_item) do
        Nanoc::Int::Item.new('parent', {}, '/parent/')
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

        it 'returns a view for the parent' do
          expect(subject.class).to eql(Nanoc::ItemView)
          expect(subject.unwrap).to eql(parent_item)
        end

        it 'returns a view with the right context' do
          expect(subject._context).to equal(view_context)
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

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '#children' do
    let(:item) do
      Nanoc::Int::Item.new('me', {}, identifier).tap { |i| i.children = children }
    end

    let(:children) do
      [Nanoc::Int::Item.new('child', {}, '/child/')]
    end

    let(:view) { described_class.new(item, view_context) }

    let(:view_context) { double(:view_context) }

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
        expect(subject[0].class).to eql(Nanoc::ItemView)
        expect(subject[0].unwrap).to eql(children[0])
      end
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
    let(:view_context) { Nanoc::ViewContext.new(reps: reps) }

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
    let(:view_context) { Nanoc::ViewContext.new(reps: reps) }

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
          Nanoc::Int::SnapshotDef.new(:last, false),
          Nanoc::Int::SnapshotDef.new(:pre, true),
          Nanoc::Int::SnapshotDef.new(:post, false),
          Nanoc::Int::SnapshotDef.new(:specific, true),
        ]
        ir.snapshot_contents = {
          last: Nanoc::Int::TextualContent.new('Last Hallo'),
          pre: Nanoc::Int::TextualContent.new('Pre Hallo'),
          post: Nanoc::Int::TextualContent.new('Post Hallo'),
          specific: Nanoc::Int::TextualContent.new('Specific Hallo'),
        }
      end
    end

    context 'requesting implicit default rep' do
      let(:params) { {} }

      before do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_started, item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_ended, item).ordered
      end

      it { is_expected.to eq('Pre Hallo') }

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('Specific Hallo') }
      end
    end

    context 'requesting explicit default rep' do
      let(:params) { { rep: :default } }

      before do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_started, item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_ended, item).ordered
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
    let(:view_context) { Nanoc::ViewContext.new(reps: reps) }

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
          last: '/about/',
          specific: '/about.txt',
        }
      end
    end

    context 'requesting implicit default rep' do
      let(:params) { {} }

      before do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_started, item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_ended, item).ordered
      end

      it { is_expected.to eq('/about/') }

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('/about.txt') }
      end
    end

    context 'requesting explicit default rep' do
      let(:params) { { rep: :default } }

      before do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_started, item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_ended, item).ordered
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
end
