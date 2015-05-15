# encoding: utf-8

describe Nanoc::MutableLayoutCollectionView do
  let(:wrapped) { double(:wrapped) }
  let(:view) { described_class.new(wrapped) }

  let(:config) do
    { pattern_syntax: 'glob' }
  end

  describe '#each' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << Nanoc::Int::Layout.new('content', {}, '/asdf/')
      end
    end

    it 'returns mutable views' do
      view.each { |l| l[:seen] = true }
      expect(wrapped['/asdf/'][:seen]).to eql(true)
    end

    it 'returns self' do
      ret = view.each { |l| l[:seen] = true }
      expect(ret).to equal(view)
    end
  end

  describe '#create' do
    let(:layout) do
      Nanoc::Int::Layout.new('content', {}, '/asdf/')
    end

    let(:mutable_layout_collection) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << layout
      end
    end

    let(:view) { described_class.new(mutable_layout_collection) }

    it 'creates an object' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(mutable_layout_collection.size).to eq(2)
      expect(mutable_layout_collection['/new/'].raw_content).to eq('new content')
    end

    it 'returns self' do
      ret = view.create('new content', { title: 'New Page' }, '/new/')
      expect(ret).to equal(view)
    end
  end

  describe '#delete_if' do
    let(:mutable_layout_collection) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << Nanoc::Int::Layout.new('content', {}, '/asdf/')
      end
    end

    let(:view) { described_class.new(mutable_layout_collection) }

    it 'deletes matching' do
      view.delete_if { |l| l.raw_content == 'content' }
      expect(mutable_layout_collection).to be_empty
    end

    it 'deletes no non-matching' do
      view.delete_if { |l| l.raw_content == 'blah' }
      expect(mutable_layout_collection).not_to be_empty
    end

    it 'yields mutable layout views' do
      view.delete_if do |l|
        expect(l.class).to equal(Nanoc::MutableLayoutView)
        false
      end
    end

    it 'returns self' do
      ret = view.delete_if { |l| false }
      expect(ret).to equal(view)
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
        expect(subject.class).to equal(Nanoc::MutableLayoutView)
        expect(subject.unwrap).to equal(layout_home)
      end
    end

    context 'glob' do
      let(:arg) { '/home.*' }

      it 'returns wrapped layout' do
        expect(subject.class).to equal(Nanoc::MutableLayoutView)
        expect(subject.unwrap).to equal(layout_home)
      end
    end

    context 'regex' do
      let(:arg) { %r{\A/home} }

      it 'returns wrapped layout' do
        expect(subject.class).to equal(Nanoc::MutableLayoutView)
        expect(subject.unwrap).to equal(layout_home)
      end
    end
  end
end
