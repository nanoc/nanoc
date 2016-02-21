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

  describe '#[]=' do
    subject { configuration[key] = value }

    let(:key) { :animal }
    let(:value) { 'donkey' }

    it 'sets the value' do
      expect { subject }.to change { configuration[key] }.from(nil).to(value)
    end

    it 'returns value' do
      expect(subject).to be value
    end
  end

  describe '#update' do
    subject { configuration.update(hash_with_update) }

    let(:hash_with_update) { { animal: 'donkey' } }

    it 'sets the value' do
      expect { subject }.to change { configuration[:animal] }.from(nil).to('donkey')
    end

    it 'returns self' do
      expect(subject).to be configuration
    end
  end
end
