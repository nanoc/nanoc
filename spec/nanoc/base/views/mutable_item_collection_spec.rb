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
  end

  describe '#concat' do
    let(:mutable_item_collection) do
      [Nanoc::Int::Item.new('content', {}, '/asdf/')]
    end

    let(:items_array_to_concat) do
      [Nanoc::Int::Item.new('shiny', {}, '/new/')]
    end

    let(:view) { described_class.new(mutable_item_collection) }

    subject { view.concat(items_array_to_concat) }

    it 'concats' do
      expect { subject }.to change { view.size }.from(1).to(2)
      expect(view[1].unwrap).to eql(items_array_to_concat[0])
    end
  end
end
