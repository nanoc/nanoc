describe Nanoc::Int::RuleMemoryActions::Snapshot do
  let(:action) { described_class.new(:before_layout, true) }

  describe '#serialize' do
    subject { action.serialize }
    it { is_expected.to eql([:snapshot, :before_layout, true]) }
  end

  describe '#to_s' do
    subject { action.to_s }
    it { is_expected.to eql('snapshot :before_layout, final: true') }
  end

  describe '#inspect' do
    subject { action.inspect }
    it { is_expected.to eql('<Nanoc::Int::RuleMemoryActions::Snapshot :before_layout, true>') }
  end
end
