# frozen_string_literal: true

describe Nanoc::Core::BinaryContent do
  describe '#initialize' do
    let(:content) { described_class.new('/foo.dat') }

    it 'sets filename' do
      expect(content.filename).to eql('/foo.dat')
    end

    context 'with relative filename' do
      let(:content) { described_class.new('foo.dat') }

      it 'errors' do
        expect { content }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#binary?' do
    subject { content.binary? }
    let(:content) { described_class.new('/foo.dat') }
    it { is_expected.to eql(true) }
  end

  describe '#freeze' do
    let(:content) { described_class.new('/foo.dat') }

    before do
      content.freeze
    end

    it 'prevents changes' do
      expect(content.filename).to be_frozen
      expect { content.filename << 'asdf' }.to raise_frozen_error
    end
  end
end
