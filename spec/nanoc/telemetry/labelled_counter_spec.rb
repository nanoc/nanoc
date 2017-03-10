describe Nanoc::Telemetry::LabelledCounter do
  subject(:counter) { described_class.new }

  describe 'new counter' do
    it 'starts at 0' do
      expect(subject.value(filter: :erb)).to eq(0)
      expect(subject.value(filter: :haml)).to eq(0)
    end

    it 'has no values' do
      expect(subject.values).to eq({})
    end
  end

  describe '#increment' do
    subject { counter.increment(filter: :erb) }

    it 'increments the matching value' do
      expect { subject }
        .to change { counter.value(filter: :erb) }
        .from(0)
        .to(1)
    end

    it 'does not increment any other value' do
      expect(counter.value(filter: :haml)).to eq(0)
      expect { subject }
        .not_to change { counter.value(filter: :haml) }
    end

    it 'correctly changes #values' do
      expect { subject }
        .to change { counter.values }
        .from({})
        .to({ filter: :erb } => 1)
    end
  end

  describe '#get' do
    subject { counter.get(filter: :erb) }

    context 'not incremented' do
      its(:value) { is_expected.to eq(0) }
    end

    context 'incremented' do
      before { counter.increment(filter: :erb) }
      its(:value) { is_expected.to eq(1) }
    end

    context 'other incremented' do
      before { counter.increment(filter: :haml) }
      its(:value) { is_expected.to eq(0) }
    end
  end
end
