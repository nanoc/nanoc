# frozen_string_literal: true

describe Nanoc::Telemetry do
  subject { described_class.new }

  example do
    expect(subject.counter(:filters).values).to eq({})
    expect(subject.counter(:filters).get(:erb).value).to eq(0)
    expect(subject.counter(:filters).value(:erb)).to eq(0)

    subject.counter(:filters).increment(:erb)
    expect(subject.counter(:filters).values).to eq(erb: 1)
    expect(subject.counter(:filters).get(:erb).value).to eq(1)
    expect(subject.counter(:filters).value(:erb)).to eq(1)
  end

  example do
    subject.summary(:filters).observe(0.1, :erb)
    expect(subject.summary(:filters).quantile(0.0, :erb)).to be_within(0.00001).of(0.1)
    expect(subject.summary(:filters).quantile(0.5, :erb)).to be_within(0.00001).of(0.1)
    expect(subject.summary(:filters).quantile(1.0, :erb)).to be_within(0.00001).of(0.1)

    subject.summary(:filters).observe(1.1, :erb)
    expect(subject.summary(:filters).quantile(0.0, :erb)).to be_within(0.00001).of(0.1)
    expect(subject.summary(:filters).quantile(0.5, :erb)).to be_within(0.00001).of(0.6)
    expect(subject.summary(:filters).quantile(1.0, :erb)).to be_within(0.00001).of(1.1)
  end
end
