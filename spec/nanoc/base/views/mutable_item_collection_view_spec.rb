# frozen_string_literal: true

describe Nanoc::MutableItemCollectionView do
  let(:view_class) { Nanoc::MutableItemView }
  let(:collection_class) { Nanoc::Int::ItemCollection }
  it_behaves_like 'an identifiable collection'
  it_behaves_like 'a mutable identifiable collection'

  let(:config) do
    { string_pattern_type: 'glob' }
  end

  describe '#create' do
    let(:item) do
      Nanoc::Int::Layout.new('content', {}, '/asdf/')
    end

    let(:wrapped) do
      Nanoc::Int::ItemCollection.new(config, [item])
    end

    let(:view) { described_class.new(wrapped, nil) }

    it 'creates an object' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(view.unwrap.size).to eq(2)
      expect(view.unwrap['/new/'].content.string).to eq('new content')
    end

    it 'does not update wrapped' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(wrapped.size).to eq(1)
      expect(wrapped['/new']).to be_nil
    end

    it 'returns self' do
      ret = view.create('new content', { title: 'New Page' }, '/new/')
      expect(ret).to equal(view)
    end
  end

  describe '#inspect' do
    let(:wrapped) do
      Nanoc::Int::ItemCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { double(:view_context) }
    let(:config) { { string_pattern_type: 'glob' } }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::MutableItemCollectionView>') }
  end
end
