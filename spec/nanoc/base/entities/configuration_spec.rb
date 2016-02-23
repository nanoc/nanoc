describe Nanoc::Int::Configuration do
  let(:configuration) { described_class.new(hash) }

  let(:hash) { { foo: 'bar' } }

  describe '#key?' do
    subject { configuration.key?(key) }

    context 'non-existent key' do
      let(:key) { :donkey }
      it { is_expected.not_to be }
    end

    context 'existent key' do
      let(:key) { :foo }
      it { is_expected.to be }
    end
  end
end
