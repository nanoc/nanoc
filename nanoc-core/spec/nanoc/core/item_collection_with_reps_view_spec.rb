# frozen_string_literal: true

require_relative 'support/identifiable_collection_view_examples'

describe Nanoc::Core::ItemCollectionWithRepsView do
  let(:view_class) { Nanoc::Core::CompilationItemView }
  let(:collection_class) { Nanoc::Core::ItemCollection }

  it_behaves_like 'an identifiable collection view' do
    let(:element_class) { Nanoc::Core::Item }
  end

  describe '#inspect' do
    subject { view.inspect }

    let(:wrapped) do
      Nanoc::Core::ItemCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { nil }
    let(:config) { { string_pattern_type: 'glob' } }

    it { is_expected.to eql('<Nanoc::Core::ItemCollectionWithRepsView>') }
  end
end
