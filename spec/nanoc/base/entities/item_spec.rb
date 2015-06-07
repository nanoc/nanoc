describe Nanoc::Int::Item do
  it_behaves_like 'a document'

  describe '#freeze' do
    let(:item) { described_class.new('Hallo', { foo: { bar: 'asdf' } }, '/foo.md') }

    before do
      item.freeze
    end

    it 'prevents changes to children' do
      expect { item.children << :lol }.to raise_frozen_error
    end
  end
end
