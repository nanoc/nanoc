# frozen_string_literal: true

describe Nanoc::External::Filter do
  example do
    filter = described_class.new({})

    src = <<-SHAKESPEARE
    Shall I compare thee to a Summer's day?
    Thou art more lovely and more temperate
    SHAKESPEARE

    res = filter.run(src, exec: 'wc', options: %w[-l])
    expect(res.strip).to eq('2')
  end
end
