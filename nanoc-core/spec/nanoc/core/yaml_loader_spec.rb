# frozen_string_literal: true

describe Nanoc::Core::YamlLoader do
  subject(:loader) { described_class }

  let(:yaml_input) do
    <<~YAML
      point: &point_data
        x: 42
        y: 43
      rect:
        origin: *point_data
        extent: {w: 10, h: 11}
    YAML
  end
  let(:expected_output) do
    {
      'point' => { 'x' => 42, 'y' => 43 },
      'rect' => {
        'origin' => { 'x' => 42, 'y' => 43 },
        'extent' => { 'w' => 10, 'h' => 11 },
      },
    }
  end

  describe 'load' do
    it 'accepts YAML aliases' do
      expect(loader.load(yaml_input)).to eq expected_output
    end
  end
end
