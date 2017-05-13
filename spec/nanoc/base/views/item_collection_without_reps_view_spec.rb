# frozen_string_literal: true

describe Nanoc::ItemCollectionWithoutRepsView do
  let(:view_class) { Nanoc::ItemWithoutRepsView }
  it_behaves_like 'an identifiable collection'

  describe '#inspect' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { double(:view_context) }
    let(:config) { { string_pattern_type: 'glob' } }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::ItemCollectionWithoutRepsView>') }
  end
end
