# frozen_string_literal: true

describe Nanoc::Core::MutableConfigView do
  let(:config) { {} }
  let(:view) { described_class.new(config, nil) }

  describe '#[]=' do
    it 'sets attributes' do
      view[:awesomeness] = 'rather high'
      expect(config[:awesomeness]).to eq('rather high')
    end
  end

  describe '#inspect' do
    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::Core::MutableConfigView>') }
  end
end
