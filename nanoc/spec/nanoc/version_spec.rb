# frozen_string_literal: true

describe Nanoc::VERSION do
  it 'is the same as Nanoc::Core::VERSION' do
    expect(Nanoc::VERSION).to eq(Nanoc::Core::VERSION)
  end
end
