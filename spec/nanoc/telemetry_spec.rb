describe Nanoc::Telemetry do
  subject { described_class.new }

  example do
    expect(subject.counter(:filters).values).to eq({})
    expect(subject.counter(:filters).get(identifier: :erb).value).to eq(0)
    expect(subject.counter(:filters).value(identifier: :erb)).to eq(0)

    subject.counter(:filters).increment(identifier: :erb)
    expect(subject.counter(:filters).values).to eq({ identifier: :erb } => 1)
    expect(subject.counter(:filters).get(identifier: :erb).value).to eq(1)
    expect(subject.counter(:filters).value(identifier: :erb)).to eq(1)
  end

  example do
    subject.summary(:filters).observe(0.1, identifier: :erb)
    expect(subject.summary(:filters).quantile(0.0, identifier: :erb)).to be_within(0.00001).of(0.1)
    expect(subject.summary(:filters).quantile(0.5, identifier: :erb)).to be_within(0.00001).of(0.1)
    expect(subject.summary(:filters).quantile(1.0, identifier: :erb)).to be_within(0.00001).of(0.1)

    subject.summary(:filters).observe(1.1, identifier: :erb)
    expect(subject.summary(:filters).quantile(0.0, identifier: :erb)).to be_within(0.00001).of(0.1)
    expect(subject.summary(:filters).quantile(0.5, identifier: :erb)).to be_within(0.00001).of(0.6)
    expect(subject.summary(:filters).quantile(1.0, identifier: :erb)).to be_within(0.00001).of(1.1)
  end
end
