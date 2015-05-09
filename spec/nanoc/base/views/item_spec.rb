# encoding: utf-8

describe Nanoc::ItemView do
  describe '#== and #eql?' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    context 'comparing with item with same identifier' do
      let(:other) { Nanoc::Int::Item.new('content', {}, '/asdf/') }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with item with different identifier' do
      let(:other) { Nanoc::Int::Item.new('content', {}, '/fdsa/') }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end

    context 'comparing with item view with same identifier' do
      let(:other) { Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/asdf/')) }

      it 'is equal' do
        expect(view).to eq(other)
        expect(view).to eql(other)
      end
    end

    context 'comparing with item view with different identifier' do
      let(:other) { Nanoc::ItemView.new(Nanoc::Int::Item.new('content', {}, '/fdsa/')) }

      it 'is not equal' do
        expect(view).not_to eq(other)
        expect(view).not_to eql(other)
      end
    end
  end

  describe '#raw_content' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item) }

    subject { view.raw_content }

    it { should eq('content') }
  end

  describe '#hash' do
    let(:item) { double(:item, identifier: '/foo/') }
    let(:view) { described_class.new(item) }

    subject { view.hash }

    it { should == described_class.hash ^ '/foo/'.hash }
  end
end
