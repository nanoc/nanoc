# frozen_string_literal: true

describe Nanoc::Int::Site do
  describe '#freeze' do
    let(:site) do
      described_class.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
      )
    end

    let(:config) do
      Nanoc::Int::Configuration.new.with_defaults
    end

    let(:code_snippets) do
      [
        Nanoc::Int::CodeSnippet.new('FOO = 123', 'hello.rb'),
        Nanoc::Int::CodeSnippet.new('BAR = 123', 'hi.rb'),
      ]
    end

    let(:items) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [
          Nanoc::Int::Item.new('foo', {}, '/foo.md'),
          Nanoc::Int::Item.new('bar', {}, '/bar.md'),
        ],
      )
    end

    let(:layouts) do
      Nanoc::Int::IdentifiableCollection.new(
        config,
        [
          Nanoc::Int::Layout.new('foo', {}, '/foo.md'),
          Nanoc::Int::Layout.new('bar', {}, '/bar.md'),
        ],
      )
    end

    before do
      site.freeze
    end

    it 'freezes the configuration' do
      expect(site.config).to be_frozen
    end

    it 'freezes the configuration contents' do
      expect(site.config[:output_dir]).to be_frozen
    end

    it 'freezes items collection' do
      expect(site.items).to be_frozen
    end

    it 'freezes individual items' do
      expect(site.items).to all(be_frozen)
    end

    it 'freezes layouts collection' do
      expect(site.layouts).to be_frozen
    end

    it 'freezes individual layouts' do
      expect(site.layouts).to all(be_frozen)
    end

    it 'freezes code snippets collection' do
      expect(site.code_snippets).to be_frozen
    end

    it 'freezes individual code snippets' do
      expect(site.code_snippets).to all(be_frozen)
    end
  end
end
