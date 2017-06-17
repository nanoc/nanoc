# frozen_string_literal: true

describe Nanoc::Int::Compiler::Stages::CalculateChecksums do
  let(:stage) do
    described_class.new(items: items, layouts: layouts, code_snippets: code_snippets, config: config)
  end

  let(:config) do
    Nanoc::Int::Configuration.new.with_defaults
  end

  let(:code_snippets) do
    [code_snippet]
  end

  let(:items) do
    Nanoc::Int::IdentifiableCollection.new(config, [item])
  end

  let(:layouts) do
    Nanoc::Int::IdentifiableCollection.new(config, [layout])
  end

  let(:code_snippet) do
    Nanoc::Int::CodeSnippet.new('woof!', 'dog.rb')
  end

  let(:item) do
    Nanoc::Int::Item.new('hello there', {}, '/hi.md')
  end

  let(:layout) do
    Nanoc::Int::Layout.new('t3mpl4t3', {}, '/page.erb')
  end

  describe '#run' do
    subject { stage.run }

    it 'checksums items' do
      expect(subject.checksum_for(item))
        .to eq(Nanoc::Int::Checksummer.calc(item))

      expect(subject.content_checksum_for(item))
        .to eq(Nanoc::Int::Checksummer.calc_for_content_of(item))

      expect(subject.attributes_checksum_for(item))
        .to eq(Nanoc::Int::Checksummer.calc_for_each_attribute_of(item))
    end

    it 'checksums layouts' do
      expect(subject.checksum_for(layout))
        .to eq(Nanoc::Int::Checksummer.calc(layout))

      expect(subject.content_checksum_for(layout))
        .to eq(Nanoc::Int::Checksummer.calc_for_content_of(layout))

      expect(subject.attributes_checksum_for(layout))
        .to eq(Nanoc::Int::Checksummer.calc_for_each_attribute_of(layout))
    end

    it 'checksums config' do
      expect(subject.checksum_for(config))
        .to eq(Nanoc::Int::Checksummer.calc(config))

      expect(subject.attributes_checksum_for(config))
        .to eq(Nanoc::Int::Checksummer.calc_for_each_attribute_of(config))
    end

    it 'checksums code snippets' do
      expect(subject.checksum_for(code_snippet))
        .to eq(Nanoc::Int::Checksummer.calc(code_snippet))
    end
  end
end
