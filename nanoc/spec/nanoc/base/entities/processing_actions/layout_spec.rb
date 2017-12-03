# frozen_string_literal: true

describe Nanoc::Int::ProcessingActions::Layout do
  let(:action) { described_class.new('/foo.erb', awesome: true) }

  describe '#serialize' do
    subject { action.serialize }
    it { is_expected.to eql([:layout, '/foo.erb', 'sJYzLjHGo1e4ytuDfnOLkqrt9QE=']) }
  end

  describe '#to_s' do
    subject { action.to_s }
    it { is_expected.to eql('layout "/foo.erb", {:awesome=>true}') }
  end

  describe '#inspect' do
    subject { action.inspect }
    it { is_expected.to eql('<Nanoc::Int::ProcessingActions::Layout "/foo.erb", "sJYzLjHGo1e4ytuDfnOLkqrt9QE=">') }
  end
end
