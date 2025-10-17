# frozen_string_literal: true

describe Nanoc::Core::StructuredDataLoader do
  subject(:loader) { described_class }

  describe '.for_language' do
    it 'can handle YAML' do
      expect(loader.for_language(:yaml).load('hello: world'))
        .to eq({ 'hello' => 'world' })
    end

    it 'can handle TOML' do
      expect(loader.for_language(:toml).load('hello = "world"'))
        .to eq({ 'hello' => 'world' })
    end
  end

  describe '.for_extension' do
    it 'can handle YAML' do
      expect(loader.for_extension('.yaml').load('hello: world'))
        .to eq({ 'hello' => 'world' })
    end

    it 'can handle TOML' do
      expect(loader.for_extension('.toml').load('hello = "world"'))
        .to eq({ 'hello' => 'world' })
    end
  end
end
