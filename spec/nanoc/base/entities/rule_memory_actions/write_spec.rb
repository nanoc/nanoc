describe Nanoc::Int::RuleMemoryActions::Write do
  let(:action) { described_class.new('/foo.html') }

  describe '#serialize' do
    subject { action.serialize }
    it { is_expected.to eql([:write, '/foo.html']) }
  end

  describe '#to_s' do
    subject { action.to_s }
    it { is_expected.to eql('write "/foo.html"') }
  end

  describe '#inspect' do
    subject { action.inspect }
    it { is_expected.to eql('<Nanoc::Int::RuleMemoryActions::Write "/foo.html">') }
  end
end
