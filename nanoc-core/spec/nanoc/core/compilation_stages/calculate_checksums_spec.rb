# frozen_string_literal: true

describe Nanoc::Core::CompilationStages::CalculateChecksums do
  let(:stage) do
    described_class.new(items:, layouts:, code_snippets:, config:)
  end

  let(:config) do
    Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults
  end

  let(:code_snippets) do
    [code_snippet]
  end

  let(:items) do
    Nanoc::Core::ItemCollection.new(config, [item])
  end

  let(:layouts) do
    Nanoc::Core::LayoutCollection.new(config, [layout])
  end

  let(:code_snippet) do
    Nanoc::Core::CodeSnippet.new('woof!', 'dog.rb')
  end

  let(:item) do
    Nanoc::Core::Item.new('hello there', {}, '/hi.md')
  end

  let(:layout) do
    Nanoc::Core::Layout.new('t3mpl4t3', {}, '/page.erb')
  end

  describe '#run' do
    subject { stage.run }

    it 'checksums items' do
      expect(subject.checksum_for(item))
        .to eq(Nanoc::Core::Checksummer.calc(item))

      expect(subject.content_checksum_for(item))
        .to eq(Nanoc::Core::Checksummer.calc_for_content_of(item))

      expect(subject.attributes_checksum_for(item))
        .to eq(Nanoc::Core::Checksummer.calc_for_each_attribute_of(item))
    end

    it 'checksums layouts' do
      expect(subject.checksum_for(layout))
        .to eq(Nanoc::Core::Checksummer.calc(layout))

      expect(subject.content_checksum_for(layout))
        .to eq(Nanoc::Core::Checksummer.calc_for_content_of(layout))

      expect(subject.attributes_checksum_for(layout))
        .to eq(Nanoc::Core::Checksummer.calc_for_each_attribute_of(layout))
    end

    it 'checksums config' do
      expect(subject.checksum_for(config))
        .to eq(Nanoc::Core::Checksummer.calc(config))

      expect(subject.attributes_checksum_for(config))
        .to eq(Nanoc::Core::Checksummer.calc_for_each_attribute_of(config))
    end

    it 'checksums code snippets' do
      expect(subject.checksum_for(code_snippet))
        .to eq(Nanoc::Core::Checksummer.calc(code_snippet))
    end
  end
end
