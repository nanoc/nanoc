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
end
