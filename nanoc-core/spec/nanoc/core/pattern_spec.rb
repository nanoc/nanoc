# frozen_string_literal: true

describe Nanoc::Core::Pattern do
  describe '.from' do
    it 'converts from string' do
      pattern = described_class.from('/foo/x[ab]z/bar.*')
      expect(pattern.match?('/foo/xaz/bar.html')).to be(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to be(false)
    end

    it 'converts from regex' do
      pattern = described_class.from(%r{\A/foo/x[ab]z/bar\..*\z})
      expect(pattern.match?('/foo/xaz/bar.html')).to be(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to be(false)
    end

    it 'converts from pattern' do
      pattern = described_class.from('/foo/x[ab]z/bar.*')
      pattern = described_class.from(pattern)
      expect(pattern.match?('/foo/xaz/bar.html')).to be(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to be(false)
    end

    it 'converts from symbol' do
      pattern = described_class.from(:'/foo/x[ab]z/bar.*')
      expect(pattern.match?('/foo/xaz/bar.html')).to be(true)
      expect(pattern.match?('/foo/xyz/bar.html')).to be(false)
    end

    it 'errors on other inputs' do
      expect { described_class.from(123) }.to raise_error(ArgumentError)
    end

    it 'errors with a proper error message on other inputs' do
      expect { described_class.from(nil) }
        .to raise_error(ArgumentError, 'Do not know how to convert `nil` into a Nanoc::Pattern')
    end
  end

  describe '#initialize' do
    it 'errors' do
      expect { described_class.new('/stuff') }
        .to raise_error(NotImplementedError)
    end
  end

  describe '#match?' do
    it 'errors' do
      expect { described_class.allocate.match?('/foo.md') }
        .to raise_error(NotImplementedError)
    end
  end

  describe '#captures' do
    it 'errors' do
      expect { described_class.allocate.captures('/foo.md') }
        .to raise_error(NotImplementedError)
    end
  end
end
