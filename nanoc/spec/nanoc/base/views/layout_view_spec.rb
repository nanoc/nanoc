# frozen_string_literal: true

require_relative 'support/document_view_examples'

describe Nanoc::LayoutView do
  let(:entity_class) { Nanoc::Core::Layout }
  let(:other_view_class) { Nanoc::CompilationItemView }
  it_behaves_like 'a document view'

  describe '#inspect' do
    let(:item) { Nanoc::Core::Layout.new('content', {}, '/asdf') }
    let(:view) { described_class.new(item, nil) }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::LayoutView identifier=/asdf>') }
  end
end
