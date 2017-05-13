# frozen_string_literal: true

describe Nanoc::Telemetry::Counter do
  subject(:counter) { described_class.new }

  it 'starts at 0' do
    expect(counter.value).to eq(0)
  end

  describe '#increment' do
    subject { counter.increment }

    it 'increments' do
      expect { subject }
        .to change { counter.value }
        .from(0)
        .to(1)
    end
  end
end
