# frozen_string_literal: true

describe Nanoc::Int::Item do
  it_behaves_like 'a document'

  describe '#reference' do
    let(:item) { described_class.new('hi', {}, '/foo.md') }

    it 'has the proper reference' do
      expect(item.reference).to eql('item:/foo.md')
    end
  end
end
