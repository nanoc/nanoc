describe Nanoc::Int::ProcessingActions::Snapshot do
  let(:action) { described_class.new([:before_layout], ['/foo.md']) }

  describe '#serialize' do
    subject { action.serialize }
    it { is_expected.to eql([:snapshot, [:before_layout], true, ['/foo.md']]) }
  end

  describe '#to_s' do
    subject { action.to_s }
    it { is_expected.to eql('snapshot [:before_layout], paths: ["/foo.md"]') }
  end

  describe '#inspect' do
    subject { action.inspect }
    it { is_expected.to eql('<Nanoc::Int::ProcessingActions::Snapshot [:before_layout], true, ["/foo.md"]>') }
  end

  describe '#add_path' do
    subject { action.add_path('/donkey.md') }
    its(:snapshot_names) { is_expected.to eql([:before_layout]) }
    its(:paths) { is_expected.to eql(['/foo.md', '/donkey.md']) }
  end
end
