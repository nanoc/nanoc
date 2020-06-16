# frozen_string_literal: true

describe Nanoc::CLI::StreamCleaners::UTF8 do
  subject { described_class.new }

  context 'when passed a string that is not UTF-8 encoded' do
    let(:str) { String.new('Not UTF-8', encoding: 'ASCII-8BIT') }

    it 'does not attempt to clean the string' do
      expect(str).not_to receive(:unicode_normalize)

      subject.clean(str)
    end
  end

  it 'handles all cases' do
    expect(subject.clean('┼─ “© Denis” ‘and others…’ ─┼')).to eq('+- "(c) Denis" \'and others...\' -+')
  end
end
