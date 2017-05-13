# frozen_string_literal: true

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

describe Nanoc::Int::RegexpPattern do
  let(:pattern) { described_class.new(/the answer is (\d+)/) }

  describe '#match?' do
    it 'matches' do
      expect(pattern.match?('the answer is 42')).to eql(true)
      expect(pattern.match?('the answer is donkey')).to eql(false)
    end
  end

  describe '#captures' do
    it 'returns nil if it does not match' do
      expect(pattern.captures('the answer is donkey')).to be_nil
    end

    it 'returns array if it matches' do
      expect(pattern.captures('the answer is 42')).to eql(['42'])
    end
  end

  describe '#to_s' do
    subject { pattern.to_s }

    it 'returns the regex' do
      expect(subject).to eq('(?-mix:the answer is (\d+))')
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

  describe '#captures' do
    it 'returns nil' do
      pattern = described_class.new('d*key')
      expect(pattern.captures('donkey')).to be_nil
    end
  end

  describe '#to_s' do
    let(:pattern) { described_class.new('/foo/*/bar/**/*.animal') }

    subject { pattern.to_s }

    it 'returns the regex' do
      expect(subject).to eq('/foo/*/bar/**/*.animal')
    end
  end
end
