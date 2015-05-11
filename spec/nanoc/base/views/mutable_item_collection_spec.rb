# encoding: utf-8

describe Nanoc::MutableItemCollectionView do
  describe '#each' do
    let(:mutable_item_collection) do
      [Nanoc::Int::Item.new('content', {}, '/asdf/')]
    end

    let(:view) { described_class.new(mutable_item_collection) }

    it 'returns mutable views' do
      view.each { |i| i[:seen] = true }
      expect(mutable_item_collection.first[:seen]).to eql(true)
    end

    it 'returns self' do
      ret = view.each { |i| i[:seen] = true }
      expect(ret).to equal(view)
    end
  end

  describe '#create' do
    let(:mutable_item_collection) do
      [Nanoc::Int::Item.new('content', {}, '/asdf/')]
    end

    let(:view) { described_class.new(mutable_item_collection) }

    it 'creates an object' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(mutable_item_collection.size).to eq(2)
      expect(mutable_item_collection.last.raw_content).to eq('new content')
    end

    it 'returns self' do
      ret = view.create('new content', { title: 'New Page' }, '/new/')
      expect(ret).to equal(view)
    end
  end

  describe '#delete_if' do
    let(:mutable_item_collection) do
      [Nanoc::Int::Item.new('content', {}, '/asdf/')]
    end

    let(:view) { described_class.new(mutable_item_collection) }

    it 'deletes matching' do
      view.delete_if { |i| i.raw_content == 'content' }
      expect(mutable_item_collection).to be_empty
    end

    it 'deletes no non-matching' do
      view.delete_if { |i| i.raw_content == 'blah' }
      expect(mutable_item_collection).not_to be_empty
    end

    it 'returns self' do
      ret = view.delete_if { |i| false }
      expect(ret).to equal(view)
    end
  end
end
