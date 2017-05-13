# frozen_string_literal: true

describe Nanoc::MutableItemView do
  let(:entity_class) { Nanoc::Int::Item }
  it_behaves_like 'a mutable document view'

  let(:item) { entity_class.new('content', {}, '/asdf/') }
  let(:view) { described_class.new(item, nil) }

  it 'does have rep access' do
    expect(view).not_to respond_to(:compiled_content)
    expect(view).not_to respond_to(:path)
    expect(view).not_to respond_to(:reps)
  end

  describe '#inspect' do
    let(:item) { Nanoc::Int::Item.new('content', {}, '/asdf/') }
    let(:view) { described_class.new(item, nil) }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::MutableItemView identifier=/asdf/>') }
  end
end
