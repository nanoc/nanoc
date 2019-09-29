# frozen_string_literal: true

describe Nanoc::CLI::VERSION do
  it 'is the same as Nanoc::Core::VERSION' do
    expect(Nanoc::CLI::VERSION).to eq(Nanoc::Core::VERSION)
  end
end
