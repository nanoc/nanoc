# frozen_string_literal: true

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

  describe '#update' do
    context 'with nothing' do
      subject { action.update }
      its(:snapshot_names) { is_expected.to eql([:before_layout]) }
      its(:paths) { is_expected.to eql(['/foo.md']) }
    end

    context 'with snapshot name' do
      subject { action.update(snapshot_names: [:zebra]) }
      its(:snapshot_names) { is_expected.to eql(%i[before_layout zebra]) }
      its(:paths) { is_expected.to eql(['/foo.md']) }
    end

    context 'with paths' do
      subject { action.update(paths: ['/donkey.md', '/giraffe.md']) }
      its(:snapshot_names) { is_expected.to eql([:before_layout]) }
      its(:paths) { is_expected.to eql(['/foo.md', '/donkey.md', '/giraffe.md']) }
    end
  end
end
