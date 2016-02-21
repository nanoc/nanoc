describe Nanoc::MutableConfigView do
  describe '#[]=' do
    let(:config) { {} }
    let(:view) { described_class.new(config, nil) }

    it 'sets attributes' do
      view[:awesomeness] = 'rather high'
      expect(config[:awesomeness]).to be_nil
      expect(view.updated[:awesomeness]).to eq('rather high')
    end
  end
end
