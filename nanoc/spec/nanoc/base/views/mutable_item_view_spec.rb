# frozen_string_literal: true

require_relative 'support/mutable_document_view_examples'

describe Nanoc::MutableItemView do
  let(:entity_class) { Nanoc::Core::Item }
  it_behaves_like 'a mutable document view'

  let(:item) { entity_class.new('content', {}, '/asdf') }
  let(:view) { described_class.new(item, nil) }

  it 'does have rep access' do
    expect(view).not_to respond_to(:compiled_content)
    expect(view).not_to respond_to(:path)
    expect(view).not_to respond_to(:reps)
  end

  describe '#inspect' do
    subject { view.inspect }

    let(:item) { Nanoc::Core::Item.new('content', {}, '/asdf') }
    let(:view) { described_class.new(item, nil) }

    it { is_expected.to eql('<Nanoc::MutableItemView identifier=/asdf>') }
  end
end
