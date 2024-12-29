# frozen_string_literal: true

describe Nanoc::Core::StringPattern do
  describe '#match?' do
    it 'matches simple strings' do
      pattern = described_class.new('d*key')

      expect(pattern.match?('donkey')).to be(true)
      expect(pattern.match?('giraffe')).to be(false)
    end

    it 'matches with pathname option' do
      pattern = described_class.new('/foo/*/bar/**/*.animal')

      expect(pattern.match?('/foo/x/bar/a/b/donkey.animal')).to be(true)
      expect(pattern.match?('/foo/x/bar/donkey.animal')).to be(true)
      expect(pattern.match?('/foo/x/railroad/donkey.animal')).to be(false)
    end

    it 'matches with extglob option' do
      pattern = described_class.new('{b,gl}oat')

      expect(pattern.match?('boat')).to be(true)
      expect(pattern.match?('gloat')).to be(true)
      expect(pattern.match?('stoat')).to be(false)
    end
  end

  describe '#captures' do
    it 'returns nil' do
      pattern = described_class.new('d*key')
      expect(pattern.captures('donkey')).to be_nil
    end
  end

  describe '#to_s' do
    subject { pattern.to_s }

    let(:pattern) { described_class.new('/foo/*/bar/**/*.animal') }

    it 'returns the regex' do
      expect(subject).to eq('/foo/*/bar/**/*.animal')
    end
  end

  describe 'case equality' do
    it 'can match strings' do
      input = '/software/nanoc.md'

      result =
        case input
        when described_class.from('/software/*')
          true
        else
          false
        end

      expect(result).to be(true)
    end

    it 'can match identifiers' do
      result =
        case Nanoc::Core::Identifier.new('/software/nanoc.md')
        when described_class.from('/software/*')
          true
        else
          false
        end

      expect(result).to be(true)
    end
  end
end
