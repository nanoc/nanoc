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

  describe '#[]' do
    let(:wrapped) do
      [
        Nanoc::Int::Layout.new('foo', {}, Nanoc::Identifier.new('/page.erb', style: :full)),
        Nanoc::Int::Layout.new('bar', {}, Nanoc::Identifier.new('/home.erb', style: :full)),
      ]
    end

    subject { view[arg] }

    context 'no layouts found' do
      let(:arg) { '/donkey.*' }
      it { is_expected.to equal(nil) }
    end

    context 'direct identifier' do
      let(:arg) { '/home.erb' }

      it 'returns wrapped layout' do
        expect(subject.class).to equal(Nanoc::LayoutView)
        expect(subject.unwrap).to equal(wrapped[1])
      end
    end

    context 'glob' do
      let(:arg) { '/home.*' }

      it 'returns wrapped layout' do
        expect(subject.class).to equal(Nanoc::LayoutView)
        expect(subject.unwrap).to equal(wrapped[1])
      end
    end
  end
end
