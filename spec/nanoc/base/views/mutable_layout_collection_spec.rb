describe Nanoc::MutableLayoutCollectionView do
  let(:view_class) { Nanoc::MutableLayoutView }
  it_behaves_like 'an identifiable collection'
  it_behaves_like 'a mutable identifiable collection'

  let(:config) do
    { string_pattern_type: 'glob' }
  end

  describe '#create' do
    let(:layout) do
      Nanoc::Int::Layout.new('content', {}, '/asdf/')
    end

    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << layout
      end
    end

    let(:view) { described_class.new(wrapped) }

    it 'creates an object' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(wrapped.size).to eq(2)
      expect(wrapped['/new/'].raw_content).to eq('new content')
    end

    it 'returns self' do
      ret = view.create('new content', { title: 'New Page' }, '/new/')
      expect(ret).to equal(view)
    end
  end
end
