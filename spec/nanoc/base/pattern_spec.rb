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

describe Nanoc::Int::StringPattern do
  describe '#match?' do
    it 'matches simple strings' do
      pattern = described_class.new('d*key')

      expect(pattern.match?('donkey')).to eql(true)
      expect(pattern.match?('giraffe')).to eql(false)
    end

    it 'matches with pathname option' do
      pattern = described_class.new('/foo/*/bar/**/*.animal')

      expect(pattern.match?('/foo/x/bar/a/b/donkey.animal')).to eql(true)
      expect(pattern.match?('/foo/x/bar/donkey.animal')).to eql(true)
      expect(pattern.match?('/foo/x/railroad/donkey.animal')).to eql(false)
    end

    it 'matches with extglob option' do
      pattern = described_class.new('{b,gl}oat')

      expect(pattern.match?('boat')).to eql(true)
      expect(pattern.match?('gloat')).to eql(true)
      expect(pattern.match?('stoat')).to eql(false)
    end
  end
end
