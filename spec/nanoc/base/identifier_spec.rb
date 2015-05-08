# encoding: utf-8

describe Nanoc::Identifier do
  describe '#initialize' do
    it 'does not convert already clean paths' do
      expect(described_class.new('/foo/bar/').to_s).to eql('/foo/bar/')
    end

    it 'prepends slash if necessary' do
      expect(described_class.new('foo/bar/').to_s).to eql('/foo/bar/')
    end

    it 'appends slash if necessary' do
      expect(described_class.new('/foo/bar').to_s).to eql('/foo/bar/')
    end

    it 'removes double slashes at start' do
      expect(described_class.new('//foo/bar/').to_s).to eql('/foo/bar/')
    end

    it 'removes double slashes at end' do
      expect(described_class.new('/foo/bar//').to_s).to eql('/foo/bar/')
    end
  end

  describe '#to_s' do
    it 'returns immutable string' do
      expect { described_class.new('foo/bar/').to_s << 'lols' }.to raise_error
    end
  end

  describe '#==' do
    context 'equal identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/') }
      let(:identifier_b) { described_class.new('/foo/bar//') }

      it 'is equal to identifier' do
        expect(identifier_a).to eq(identifier_b)
      end

      it 'is equal to string' do
        expect(identifier_a).to eq(identifier_b.to_s)
      end
    end

    context 'different identifiers' do
      let(:identifier_a) { described_class.new('//foo/bar/') }
      let(:identifier_b) { described_class.new('/baz/qux//') }

      it 'differs from identifier' do
        expect(identifier_a).not_to eq(identifier_b)
      end

      it 'differs from string' do
        expect(identifier_a).not_to eq(identifier_b.to_s)
      end
    end
  end

  describe '#=~' do
    let(:identifier) { described_class.new('/foo/bar/') }

    it 'matches on string' do
      expect(identifier).to be =~ %r{\A/foo/bar}
      expect(identifier).not_to be =~ %r{\A/qux/monkey}
    end
  end

  describe '#<=>' do
    let(:identifier) { described_class.new('/foo/bar/') }

    it 'compares by string' do
      expect(identifier <=> '/foo/aarghh/').to eql(1)
      expect(identifier <=> '/foo/bar/').to eql(0)
      expect(identifier <=> '/foo/qux/').to eql(-1)
    end
  end
end
