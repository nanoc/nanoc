# frozen_string_literal: true

require_relative 'support/document_view_examples'

describe Nanoc::Core::LayoutView do
  let(:entity_class) { Nanoc::Core::Layout }
  let(:other_view_class) { Nanoc::Core::CompilationItemView }

  it_behaves_like 'a document view'

  describe '#inspect' do
    subject { view.inspect }

    let(:item) { Nanoc::Core::Layout.new('content', {}, '/asdf') }
    let(:view) { described_class.new(item, nil) }

    it { is_expected.to eql('<Nanoc::Core::LayoutView identifier=/asdf>') }
  end
end
