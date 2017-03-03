describe Nanoc::Int::IdentifiableCollection do
  subject(:identifiable_collection) { described_class.new(config, objects) }

  let(:config) { Nanoc::Int::Configuration.new }
  let(:objects) { [] }

  describe '#reject' do
    subject { identifiable_collection.reject { |_| false } }

    it { is_expected.to be_a(described_class) }
  end
end
