describe Nanoc::Telemetry::LabelledSummary do
  subject(:summary) { described_class.new }

  describe '#labels' do
    subject { summary.labels }

    context 'empty summary' do
      it { is_expected.to eq([]) }
    end

    context 'some observations' do
      before do
        summary.observe(7.2, filter: :erb)
        summary.observe(5.3, filter: :erb)
        summary.observe(3.0, filter: :haml)
      end

      it { is_expected.to eq([{ filter: :erb }, { filter: :haml }]) }
    end
  end

  describe '#get' do
    subject { summary.get(filter: :erb) }

    context 'empty summary' do
      its(:count) { is_expected.to eq(0) }
    end

    context 'one observation with that label' do
      before { summary.observe(0.1, filter: :erb) }
      its(:count) { is_expected.to eq(1) }
    end

    context 'one observation with a different label' do
      before { summary.observe(0.1, filter: :haml) }
      its(:count) { is_expected.to eq(0) }
    end
  end

  describe '#map' do
    before do
      subject.observe(2.1, filter: :erb)
      subject.observe(4.1, filter: :erb)
      subject.observe(5.3, filter: :haml)
    end

    it 'yields labels and summary' do
      res = subject.map { |labels, summary| [labels[:filter], summary.avg.round(3)] }
      expect(res).to eql([[:erb, 3.1], [:haml, 5.3]])
    end
  end

  describe '#quantile' do
    before do
      subject.observe(2.1, filter: :erb)
      subject.observe(4.1, filter: :erb)
      subject.observe(5.3, filter: :haml)
    end

    it 'has proper quantiles for :erb' do
      expect(subject.quantile(0.00, filter: :erb)).to be_within(0.000001).of(2.1)
      expect(subject.quantile(0.25, filter: :erb)).to be_within(0.000001).of(2.6)
      expect(subject.quantile(0.50, filter: :erb)).to be_within(0.000001).of(3.1)
      expect(subject.quantile(0.90, filter: :erb)).to be_within(0.000001).of(3.9)
      expect(subject.quantile(0.99, filter: :erb)).to be_within(0.000001).of(4.08)
    end

    it 'has proper quantiles for :erb' do
      expect(subject.quantile(0.00, filter: :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.25, filter: :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.50, filter: :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.90, filter: :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.99, filter: :haml)).to be_within(0.000001).of(5.3)
    end
  end
end
