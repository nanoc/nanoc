# frozen_string_literal: true

describe Nanoc::Core::Layout do
  it_behaves_like 'a document'

  describe '#reference' do
    let(:layout) { described_class.new('hi', {}, '/foo.md') }

    it 'has the proper reference' do
      expect(layout.reference).to eql('layout:/foo.md')
    end
  end
end
