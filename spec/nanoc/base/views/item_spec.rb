describe Nanoc::ItemView do
  let(:entity_class) { Nanoc::Int::Item }
  it_behaves_like 'a document view'

  describe '#raw_content' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    subject { view.raw_content }

    it { should eq('content') }
  end

  describe '#parent' do
    let(:item) do
      Nanoc::Int::Item.new('me', {}, '/me/').tap { |i| i.parent = parent_item }
    end

    let(:view) { described_class.new(item) }

    subject { view.parent }

    context 'with parent' do
      let(:parent_item) do
        Nanoc::Int::Item.new('parent', {}, '/parent/')
      end

      it 'returns a view for the parent' do
        expect(subject.class).to eql(Nanoc::ItemView)
        expect(subject.unwrap).to eql(parent_item)
      end
    end

    context 'without parent' do
      let(:parent_item) do
        nil
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#children' do
    # TODO: implement
  end

  describe '#reps' do
    let(:item) { double(:item, reps: [rep_a, rep_b]) }
    let(:rep_a) { double(:rep_a) }
    let(:rep_b) { double(:rep_b) }

    let(:view) { described_class.new(item) }

    subject { view.reps }

    it 'returns a proper item rep collection' do
      expect(subject.size).to eq(2)
      expect(subject.class).to eql(Nanoc::ItemRepCollectionView)
    end
  end

  describe '#compiled_content' do
    subject { view.compiled_content(params) }

    let(:view) { described_class.new(item) }

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf/')
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.compiled = true,
        ir.snapshots = [
          Nanoc::Int::SnapshotDef.new(:last, false),
          Nanoc::Int::SnapshotDef.new(:specific, true),
        ]
        ir.content_snapshots = {
          last: Nanoc::Int::TextualContent.new('Default Hallo'),
          specific: Nanoc::Int::TextualContent.new('Specific Hallo'),
        }
      end
    end

    before do
      item.reps << rep
    end

    context 'requesting implicit default rep' do
      let(:params) { {} }

      before do
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_started, item).ordered
        expect(Nanoc::Int::NotificationCenter).to receive(:post)
          .with(:visit_ended, item).ordered
      end

      it { is_expected.to eq('Default Hallo') }

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

      it { is_expected.to eq('Default Hallo') }

      context 'requesting explicit snapshot' do
        let(:params) { { snapshot: :specific } }

        it { is_expected.to eq('Specific Hallo') }
      end
    end

    context 'requesting other rep' do
      let(:params) { { rep: :other } }

      it 'raises an error' do
        expect { subject }.to raise_error
      end
    end
  end

  describe '#path' do
    subject { view.path(params) }

    let(:view) { described_class.new(item) }

    let(:item) do
      Nanoc::Int::Item.new('content', {}, '/asdf.md')
    end

    let(:rep) do
      Nanoc::Int::ItemRep.new(item, :default).tap do |ir|
        ir.paths = {
          last: '/about/',
          specific: '/about.txt',
        }
      end
    end

    before do
      item.reps << rep
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
        expect { subject }.to raise_error
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
