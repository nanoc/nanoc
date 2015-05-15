# encoding: utf-8

describe Nanoc::LayoutCollectionView do
  let(:view) { described_class.new(wrapped) }

  let(:config) do
    { pattern_syntax: 'glob' }
  end

  describe '#unwrap' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << Nanoc::Int::Layout.new('foo', {}, '/foo/')
        coll << Nanoc::Int::Layout.new('bar', {}, '/bar/')
        coll << Nanoc::Int::Layout.new('baz', {}, '/baz/')
      end
    end

    subject { view.unwrap }

    it 'returns self' do
      expect(subject).to equal(wrapped)
    end
  end

  describe '#each' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << Nanoc::Int::Layout.new('foo', {}, '/foo/')
        coll << Nanoc::Int::Layout.new('bar', {}, '/bar/')
        coll << Nanoc::Int::Layout.new('baz', {}, '/baz/')
      end
    end

    it 'returns self' do
      expect(view.each { |l| }).to equal(view)
    end
  end

  describe '#[]' do
    let(:layout_page) do
      Nanoc::Int::Layout.new('foo', {}, Nanoc::Identifier.new('/page.erb', style: :full))
    end

    let(:layout_home) do
      Nanoc::Int::Layout.new('bar', {}, Nanoc::Identifier.new('/home.erb', style: :full))
    end

    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << layout_page
        coll << layout_home
      end
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
        expect(subject.unwrap).to equal(layout_home)
      end
    end

    context 'glob' do
      let(:arg) { '/home.*' }

      it 'returns wrapped layout' do
        expect(subject.class).to equal(Nanoc::LayoutView)
        expect(subject.unwrap).to equal(layout_home)
      end
    end

    context 'regex' do
      let(:arg) { %r{\A/home} }

      it 'returns wrapped layout' do
        expect(subject.class).to equal(Nanoc::LayoutView)
        expect(subject.unwrap).to equal(layout_home)
      end
    end
  end
end
