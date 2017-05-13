# frozen_string_literal: true

describe Nanoc::MutableLayoutView do
  let(:entity_class) { Nanoc::Int::Layout }
  it_behaves_like 'a mutable document view'

  describe '#inspect' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::MutableLayoutView identifier=/asdf/>') }
  end
end
