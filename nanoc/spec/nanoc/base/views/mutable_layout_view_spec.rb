# frozen_string_literal: true

require_relative 'support/mutable_document_view_examples'

describe Nanoc::MutableLayoutView do
  let(:entity_class) { Nanoc::Core::Layout }
  it_behaves_like 'a mutable document view'

  describe '#inspect' do
    let(:item) { Nanoc::Core::Item.new('content', {}, '/asdf') }
    let(:view) { described_class.new(item, nil) }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::MutableLayoutView identifier=/asdf>') }
  end
end
