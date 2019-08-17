# frozen_string_literal: true

describe Nanoc::Core::RegexpPattern do
  let(:pattern) { described_class.new(/the answer is (\d+)/) }

  describe '#match?' do
    it 'matches' do
      expect(pattern.match?('the answer is 42')).to be(true)
      expect(pattern.match?('the answer is donkey')).to be(false)
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
