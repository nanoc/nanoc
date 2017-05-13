# frozen_string_literal: true

shared_examples 'an item rep collection view' do
  let(:view) { described_class.new(wrapped, view_context) }

  let(:view_context) { double(:view_context) }

  let(:wrapped) do
    [
      double(:item_rep, name: :foo),
      double(:item_rep, name: :bar),
      double(:item_rep, name: :baz),
    ]
  end

  describe '#unwrap' do
    subject { view.unwrap }

    it { should equal(wrapped) }
  end

  describe '#frozen?' do
    subject { view.frozen? }

    context 'non-frozen collection' do
      it { is_expected.to be(false) }
    end

    context 'frozen collection' do
      before { wrapped.freeze }
      it { is_expected.to be(true) }
    end
  end

  describe '#each' do
    it 'yields' do
      actual = [].tap { |res| view.each { |v| res << v } }
      expect(actual.size).to eq(3)
    end

    it 'returns self' do
      expect(view.each { |_i| }).to equal(view)
    end

    it 'yields elements with the right context' do
      view.each { |v| expect(v._context).to equal(view_context) }
    end
  end

  describe '#size' do
    subject { view.size }

    it { should == 3 }
  end

  describe '#to_ary' do
    subject { view.to_ary }

    it 'returns an array of item rep views' do
      expect(subject.class).to eq(Array)
      expect(subject.size).to eq(3)
      expect(subject[0].class).to eql(expected_view_class)
      expect(subject[0].name).to eql(:foo)
    end

    it 'returns an array with correct contexts' do
      expect(subject[0]._context).to equal(view_context)
    end
  end

  describe '#[]' do
    subject { view[name] }

    context 'when not found' do
      let(:name) { :donkey }

      it { should be_nil }
    end

    context 'when found' do
      let(:name) { :foo }

      it 'returns a view' do
        expect(subject.class).to eq(expected_view_class)
        expect(subject.name).to eq(:foo)
      end

      it 'returns a view with the correct context' do
        expect(subject._context).to equal(view_context)
      end
    end

    context 'when given a string' do
      let(:name) { 'foo' }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError, 'expected ItemRepCollectionView#[] to be called with a symbol')
      end
    end

    context 'when given a number' do
      let(:name) { 0 }

      it 'raises' do
        expect { subject }.to raise_error(ArgumentError, 'expected ItemRepCollectionView#[] to be called with a symbol (you likely want `.reps[:default]` rather than `.reps[0]`)')
      end
    end
  end

  describe '#fetch' do
    subject { view.fetch(name) }

    context 'when not found' do
      let(:name) { :donkey }

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::ItemRepCollectionView::NoSuchItemRepError)
      end
    end

    context 'when found' do
      let(:name) { :foo }

      it 'returns a view' do
        expect(subject.class).to eq(expected_view_class)
        expect(subject.name).to eq(:foo)
      end

      it 'returns a view with the correct context' do
        expect(subject._context).to equal(view_context)
      end
    end
  end

  describe '#inspect' do
    subject { view.inspect }

    it { is_expected.to eql('<' + described_class.name + '>') }
  end
end

describe Nanoc::ItemRepCollectionView do
  it_behaves_like 'an item rep collection view'
  let(:expected_view_class) { Nanoc::ItemRepView }
end
