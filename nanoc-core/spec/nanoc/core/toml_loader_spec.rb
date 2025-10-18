# frozen_string_literal: true

describe Nanoc::Core::TomlLoader do
  subject(:loader) { described_class }

  let(:input) do
    <<~TOML
      point.x = 42
      point.y = 43
    TOML
  end

  let(:expected_output) do
    {
      'point' => { 'x' => 42, 'y' => 43 },
    }
  end

  describe 'load' do
    it 'returns parsed TOML' do
      expect(loader.load(input)).to eq expected_output
    end
  end
end
