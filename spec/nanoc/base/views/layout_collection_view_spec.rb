# frozen_string_literal: true

describe Nanoc::LayoutCollectionView do
  let(:view_class) { Nanoc::LayoutView }
  let(:collection_class) { Nanoc::Int::LayoutCollection }
  it_behaves_like 'an identifiable collection'

  describe '#inspect' do
    let(:wrapped) do
      Nanoc::Int::LayoutCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { double(:view_context) }
    let(:config) { { string_pattern_type: 'glob' } }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::LayoutCollectionView>') }
  end
end
