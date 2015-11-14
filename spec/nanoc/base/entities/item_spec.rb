describe Nanoc::Int::Item do
  it_behaves_like 'a document'

  describe '#freeze' do
    let(:item) { described_class.new('Hallo', { foo: { bar: 'asdf' } }, '/foo.md') }

    before do
      item.freeze
    end

    # FIXME: Where are the tests?
  end
end
