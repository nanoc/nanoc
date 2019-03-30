# frozen_string_literal: true

require_relative 'support/identifiable_collection_view_examples'

describe Nanoc::LayoutCollectionView do
  let(:view_class) { Nanoc::LayoutView }
  let(:collection_class) { Nanoc::Core::LayoutCollection }

  it_behaves_like 'an identifiable collection view'

  describe '#inspect' do
    let(:wrapped) do
      Nanoc::Core::LayoutCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { double(:view_context) }
    let(:config) { { string_pattern_type: 'glob' } }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::LayoutCollectionView>') }
  end
end
