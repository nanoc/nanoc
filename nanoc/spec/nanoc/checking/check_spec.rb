# frozen_string_literal: true

describe Nanoc::Check do
  it 'is an alias' do
    expect(described_class).to equal(Nanoc::Checking::Check)
  end
end

describe Nanoc::Checking::Check do
  describe '.define' do
    before do
      described_class.define(:spec_check_example_1) do
        add_issue('it’s totes bad')
      end
    end

    let(:site) do
      Nanoc::Int::Site.new(
        config: config,
        code_snippets: code_snippets,
        data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
      )
    end

    let(:config)        { Nanoc::Int::Configuration.new.with_defaults }
    let(:code_snippets) { [] }
    let(:items)         { Nanoc::Int::ItemCollection.new(config, []) }
    let(:layouts)       { Nanoc::Int::LayoutCollection.new(config, []) }

    before do
      FileUtils.mkdir_p('output')
      File.write('Rules', 'passthrough "/**/*"')
    end

    it 'is discoverable' do
      expect(described_class.named(:spec_check_example_1)).not_to be_nil
    end

    it 'runs properly' do
      check = described_class.named(:spec_check_example_1).create(site)
      check.run
      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description).to eq('it’s totes bad')
    end
  end

  describe '.named' do
    it 'finds checks that exist' do
      expect(described_class.named(:internal_links)).not_to be_nil
    end

    it 'is nil for non-existent checks' do
      expect(described_class.named(:asdfaskjlfdalhsgdjf)).to be_nil
    end
  end
end
