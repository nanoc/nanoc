describe Nanoc::ItemRepView do
  describe '#== and #eql?' do
    let(:item_rep) { double(:item_rep, item: item, name: :jacques) }
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item_rep) }

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :jacques) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { double(:other_item_rep, item: other_item, name: :marvin) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with same identifier' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques)) }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with item rep with different identifier' do
      let(:other_item) { double(:other_item, identifier: '/bar/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :jacques)) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item rep with different name' do
      let(:other_item) { double(:other_item, identifier: '/foo/') }
      let(:other) { described_class.new(double(:other_item_rep, item: other_item, name: :marvin)) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#hash' do
    let(:item_rep) { double(:item_rep, item: item, name: :jacques) }
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item_rep) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash ^ :jacques.hash }
  end
end
