# encoding: utf-8

describe Nanoc::LayoutCollectionView do
  let(:wrapped) { double(:wrapped) }
  let(:view) { described_class.new(wrapped) }

  describe '#unwrap' do
    subject { view.unwrap }
    it { should equal(wrapped) }
  end

  describe '#each' do
    let(:wrapped) do
      [
        Nanoc::Int::Layout.new('foo', {}, '/foo/'),
        Nanoc::Int::Layout.new('bar', {}, '/bar/'),
        Nanoc::Int::Layout.new('baz', {}, '/baz/'),
      ]
    end

    it 'returns self' do
      expect(view.each { |l| }).to equal(view)
    end
  end
end
