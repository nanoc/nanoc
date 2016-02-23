describe Nanoc::MutableConfigView do
  describe '#[]=' do
    let(:config) { Nanoc::Int::Configuration.new }
    let(:view) { described_class.new(config, nil) }

    it 'sets attributes' do
      view[:awesomeness] = 'rather high'
      expect(config[:awesomeness]).to be_nil
      expect(view.unwrap[:awesomeness]).to eq('rather high')
    end
  end
end
