# frozen_string_literal: true

describe Nanoc::Int::ProcessingAction do
  let(:action) { described_class.new }

  it 'is abstract' do
    expect { action.serialize }.to raise_error(NotImplementedError)
    expect { action.to_s }.to raise_error(NotImplementedError)
    expect { action.inspect }.to raise_error(NotImplementedError)
  end
end
