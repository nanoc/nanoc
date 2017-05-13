# frozen_string_literal: true

describe Nanoc::Telemetry::LabelledSummary do
  subject(:summary) { described_class.new }

  describe '#empty?' do
    subject { summary.empty? }

    context 'empty summary' do
      it { is_expected.to be }
    end

    context 'some observations' do
      before do
        summary.observe(7.2, :erb)
        summary.observe(5.3, :erb)
        summary.observe(3.0, :haml)
      end

      it { is_expected.not_to be }
    end
  end

  describe '#get' do
    subject { summary.get(:erb) }

    context 'empty summary' do
      its(:count) { is_expected.to eq(0) }
    end

    context 'one observation with that label' do
      before { summary.observe(0.1, :erb) }
      its(:count) { is_expected.to eq(1) }
    end

    context 'one observation with a different label' do
      before { summary.observe(0.1, :haml) }
      its(:count) { is_expected.to eq(0) }
    end
  end

  describe '#map' do
    before do
      subject.observe(2.1, :erb)
      subject.observe(4.1, :erb)
      subject.observe(5.3, :haml)
    end

    it 'yields label and summary' do
      res = subject.map { |label, summary| [label, summary.avg.round(3)] }
      expect(res).to eql([[:erb, 3.1], [:haml, 5.3]])
    end
  end

  describe '#quantile' do
    before do
      subject.observe(2.1, :erb)
      subject.observe(4.1, :erb)
      subject.observe(5.3, :haml)
    end

    it 'has proper quantiles for :erb' do
      expect(subject.quantile(0.00, :erb)).to be_within(0.000001).of(2.1)
      expect(subject.quantile(0.25, :erb)).to be_within(0.000001).of(2.6)
      expect(subject.quantile(0.50, :erb)).to be_within(0.000001).of(3.1)
      expect(subject.quantile(0.90, :erb)).to be_within(0.000001).of(3.9)
      expect(subject.quantile(0.99, :erb)).to be_within(0.000001).of(4.08)
    end

    it 'has proper quantiles for :erb' do
      expect(subject.quantile(0.00, :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.25, :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.50, :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.90, :haml)).to be_within(0.000001).of(5.3)
      expect(subject.quantile(0.99, :haml)).to be_within(0.000001).of(5.3)
    end
  end
end
