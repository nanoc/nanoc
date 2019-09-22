# frozen_string_literal: true

require_relative 'support/document_view_examples'

describe Nanoc::Base::LayoutView do
  let(:entity_class) { Nanoc::Core::Layout }
  let(:other_view_class) { Nanoc::Base::CompilationItemView }

  it_behaves_like 'a document view'

  describe '#inspect' do
    subject { view.inspect }

    let(:item) { Nanoc::Core::Layout.new('content', {}, '/asdf') }
    let(:view) { described_class.new(item, nil) }

    it { is_expected.to eql('<Nanoc::Base::LayoutView identifier=/asdf>') }
  end
end
