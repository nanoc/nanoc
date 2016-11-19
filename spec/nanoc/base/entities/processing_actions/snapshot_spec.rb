describe Nanoc::Int::ProcessingActions::Snapshot do
  let(:action) { described_class.new(:before_layout, true, '/foo.md') }

  describe '#serialize' do
    subject { action.serialize }
    it { is_expected.to eql([:snapshot, :before_layout, true, '/foo.md']) }
  end

  describe '#to_s' do
    subject { action.to_s }
    it { is_expected.to eql('snapshot :before_layout, final: true, path: "/foo.md"') }
  end

  describe '#inspect' do
    subject { action.inspect }
    it { is_expected.to eql('<Nanoc::Int::ProcessingActions::Snapshot :before_layout, true, "/foo.md">') }
  end
end
