# frozen_string_literal: true

describe Nanoc::Checking::Checks::HTML do
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
  let(:items)         { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts)       { Nanoc::Core::LayoutCollection.new(config, []) }

  before do
    FileUtils.mkdir_p('output')
    File.write('Rules', 'passthrough "/**/*"')
  end

  it 'handles good HTML' do
    VCR.use_cassette('html_run_ok') do
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h1>')

      check.run

      expect(check.issues).to be_empty
    end
  end

  it 'handles bad HTML' do
    VCR.use_cassette('html_run_error') do
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h2>')

      check.run

      expect(check.issues.length).to be(3)
      expect(check.issues.to_a[0].description)
        .to eq('line 1: Start tag seen without seeing a doctype first. Expected e.g. “<!DOCTYPE html>”.: <h1>Hi!</h2>')
      expect(check.issues.to_a[1].description)
        .to eq('line 1: Element “head” is missing a required instance of child element “title”.: <h1>Hi!</h2>')
      expect(check.issues.to_a[2].description)
        .to eq('line 1: End tag “h1” seen, but there were open elements.: <h1>Hi!</h2>')
    end
  end
end
