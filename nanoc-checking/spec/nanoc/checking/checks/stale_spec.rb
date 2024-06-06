# frozen_string_literal: true

describe Nanoc::Checking::Checks::Stale do
  let(:check) { described_class.create(site) }

  let(:site) do
    Nanoc::Core::Site.new(
      config:,
      code_snippets:,
      data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
    )
  end

  let(:config)        { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:code_snippets) { [] }
  let(:layouts)       { Nanoc::Core::LayoutCollection.new(config, []) }

  let(:items) do
    Nanoc::Core::ItemCollection.new(
      config,
      Dir['content/*'].map { |fn| Nanoc::Core::Item.new('stuff', {}, fn.sub(/^content/, '')) },
    )
  end

  before do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('output')
    File.write('Rules', 'passthrough "/**/*"')
  end

  it 'does not error when there are no files' do
    check.run
    expect(check.issues).to be_empty
  end

  it 'does not error when input matches output' do
    File.write('content/index.html', 'stuff')
    File.write('output/index.html', 'stuff')

    check.run
    expect(check.issues).to be_empty
  end

  it 'errors when there is an output file with no matching input file' do
    File.write('content/index.html', 'stuff')
    File.write('output/WRONG.html', 'stuff')

    check.run
    expect(check.issues.size).to eq(1)
    expect(check.issues.to_a[0].description).to eq('file without matching item')
    expect(check.issues.to_a[0].subject).to eq('output/WRONG.html')
  end

  context 'with excludes' do
    let(:config) do
      super().merge(prune: { exclude: ['excluded.html'] })
    end

    it 'honors excludes' do
      File.write('content/index.html', 'stuff')
      File.write('output/excluded.html', 'stuff')

      check.run
      expect(check.issues).to be_empty
    end
  end
end
