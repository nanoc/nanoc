# frozen_string_literal: true

describe Nanoc::LayoutView do
  let(:entity_class) { Nanoc::Int::Layout }
  let(:other_view_class) { Nanoc::ItemWithRepsView }
  it_behaves_like 'a document view'

  describe '#inspect' do
    let(:item) { Nanoc::Int::Layout.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::LayoutView identifier=/asdf/>') }
  end
end
