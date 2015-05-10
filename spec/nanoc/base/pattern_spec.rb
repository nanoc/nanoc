# encoding: utf-8

describe Nanoc::Int::Pattern do
  describe '.from' do
    it 'converts from string' do
      pattern = described_class.from('/foo/x[ab]z/bar.*')
      expect(pattern.match?('/foo/xaz/bar.html')).to eql(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to eql(false)
    end

    it 'converts from regex' do
      pattern = described_class.from(%r{\A/foo/x[ab]z/bar\..*\z})
      expect(pattern.match?('/foo/xaz/bar.html')).to eql(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to eql(false)
    end

    it 'converts from pattern' do
      pattern = described_class.from('/foo/x[ab]z/bar.*')
      pattern = described_class.from(pattern)
      expect(pattern.match?('/foo/xaz/bar.html')).to eql(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to eql(false)
    end
  end
end
