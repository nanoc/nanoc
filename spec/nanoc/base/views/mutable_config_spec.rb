describe Nanoc::MutableConfigView do
  describe '#[]=' do
    let(:config) { {} }
    let(:view) { described_class.new(config) }

    it 'sets attributes' do
      view[:awesomeness] = 'rather high'
      expect(config[:awesomeness]).to eq('rather high')
    end
  end
end
