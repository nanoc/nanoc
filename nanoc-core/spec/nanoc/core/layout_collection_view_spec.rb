# frozen_string_literal: true

require_relative 'support/identifiable_collection_view_examples'

describe Nanoc::Core::LayoutCollectionView do
  let(:view_class) { Nanoc::Core::LayoutView }
  let(:collection_class) { Nanoc::Core::LayoutCollection }

  it_behaves_like 'an identifiable collection view' do
    let(:element_class) { Nanoc::Core::Layout }
  end

  describe '#inspect' do
    subject { view.inspect }

    let(:wrapped) do
      Nanoc::Core::LayoutCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { nil }
    let(:config) { { string_pattern_type: 'glob' } }

    it { is_expected.to eql('<Nanoc::Core::LayoutCollectionView>') }
  end
end
