describe Nanoc::MutableLayoutView do
  describe '#[]=' do
    let(:layout) { Nanoc::Int::Layout.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(layout) }

    it 'sets attributes' do
      view[:title] = 'Donkey'
      expect(view[:title]).to eq('Donkey')
    end
  end
end
