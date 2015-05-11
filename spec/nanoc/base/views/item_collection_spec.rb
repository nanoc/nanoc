# encoding: utf-8

describe Nanoc::ItemCollectionView do
  let(:wrapped) { double(:wrapped) }
  let(:view) { described_class.new(wrapped) }

  describe '#unwrap' do
    subject { view.unwrap }
    it { should equal(wrapped) }
  end

  describe '#each' do
    # …
  end

  describe '#size' do
    let(:wrapped) do
      [
        Nanoc::Int::Item.new('foo', {}, '/foo/'),
        Nanoc::Int::Item.new('bar', {}, '/bar/'),
        Nanoc::Int::Item.new('baz', {}, '/baz/'),
      ]
    end

    subject { view.size }

    it { should == 3 }
  end

  describe '#at' do
    subject { view.at(arg) }

    let(:arg) { 'some argument' }

    context 'wrapped returns item' do
      let(:item) { double(:item) }

      before do
        expect(wrapped).to receive(:at).with(arg) { item }
      end

      it 'returns a wrapped item' do
        expect(subject.class).to equal(Nanoc::ItemView)
        expect(subject.unwrap).to equal(item)
      end
    end

    context 'wrapped returns nil' do
      before do
        expect(wrapped).to receive(:at).with(arg) { nil }
      end

      it { should equal(nil) }
    end
  end

  describe '#[]' do
    subject { view[arg] }

    let(:arg) { 'some argument' }

    context 'wrapped returns array' do
      let(:item) { double(:item) }

      before do
        expect(wrapped).to receive(:[]).with(arg) { [item] }
      end

      it 'returns wrapped items' do
        expect(subject.size).to equal(1)
        expect(subject[0].class).to equal(Nanoc::ItemView)
        expect(subject[0].unwrap).to equal(item)
      end
    end

    context 'wrapped returns nil' do
      before do
        expect(wrapped).to receive(:[]).with(arg) { nil }
      end

      it { should equal(nil) }
    end

    context 'wrapped returns item' do
      let(:item) { double(:item) }

      before do
        expect(wrapped).to receive(:[]).with(arg) { item }
      end

      it 'returns wrapped item' do
        expect(subject.class).to equal(Nanoc::ItemView)
        expect(subject.unwrap).to equal(item)
      end
    end
  end
end
