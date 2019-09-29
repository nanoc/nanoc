# frozen_string_literal: true

describe Nanoc::CLI::StreamCleaners::UTF8 do
  subject { described_class.new }

  it 'handles all cases' do
    expect(subject.clean('┼─ “© Denis” ‘and others…’ ─┼')).to eq('+- "(c) Denis" \'and others...\' -+')
  end
end
