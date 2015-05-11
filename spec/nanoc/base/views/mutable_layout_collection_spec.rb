# encoding: utf-8

describe Nanoc::MutableLayoutCollectionView do
  describe '#each' do
    let(:mutable_layout_collection) do
      [Nanoc::Int::Layout.new('content', {}, '/asdf/')]
    end

    let(:view) { described_class.new(mutable_layout_collection) }

    it 'returns mutable views' do
      view.each { |l| l[:seen] = true }
      expect(mutable_layout_collection.first[:seen]).to eql(true)
    end

    it 'returns self' do
      ret = view.each { |l| l[:seen] = true }
      expect(ret).to equal(view)
    end
  end

  describe '#create' do
    let(:mutable_layout_collection) do
      [Nanoc::Int::Layout.new('content', {}, '/asdf/')]
    end

    let(:view) { described_class.new(mutable_layout_collection) }

    it 'creates an object' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(mutable_layout_collection.size).to eq(2)
      expect(mutable_layout_collection.last.raw_content).to eq('new content')
    end

    it 'returns self' do
      ret = view.create('new content', { title: 'New Page' }, '/new/')
      expect(ret).to equal(view)
    end
  end

  describe '#delete_if' do
    let(:mutable_layout_collection) do
      [Nanoc::Int::Layout.new('content', {}, '/asdf/')]
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

    it 'returns self' do
      ret = view.delete_if { |l| false }
      expect(ret).to equal(view)
    end
  end
end
