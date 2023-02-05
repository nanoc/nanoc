# frozen_string_literal: true

describe Nanoc::Core::Item do
  it_behaves_like 'a document'

  describe '#reference' do
    let(:item) { described_class.new('hi', {}, '/foo.md') }

    it 'has the proper reference' do
      expect(item.reference).to eql('item:/foo.md')
    end

    it 'updates reference after updating identifier' do
      expect { item.identifier = '/foo2.md' }
        .to change(item, :reference)
        .from('item:/foo.md')
        .to('item:/foo2.md')
    end
  end
end
