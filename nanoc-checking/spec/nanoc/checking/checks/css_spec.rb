# frozen_string_literal: true

describe Nanoc::Checking::Checks::CSS do
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

  it 'handles good CSS' do
    VCR.use_cassette('css_run_ok') do
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h1>')
      File.write('output/style.css', 'h1 { color: red; }')

      check.run

      expect(check.issues).to be_empty
    end
  end

  it 'handles bad CSS' do
    VCR.use_cassette('css_run_error') do
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h1>')
      File.write('output/style.css', 'h1 { coxlor: rxed; }')

      check.run

      expect(check.issues.length).to be(1)
      expect(check.issues.to_a[0].description).to eq(
        "line 1: Property “coxlor” doesn't exist. The closest matching property name is “color”: h1 { coxlor: rxed; }",
      )
    end
  end

  it 'handles parse errors' do
    VCR.use_cassette('css_run_parse_error') do
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h1>')
      File.write('output/style.css', 'h1 { ; {')

      check.run

      expect(check.issues.length).to be(1)
      expect(check.issues.to_a[0].description).to eq(
        'line 1: Parse Error: h1 { ; {',
      )
    end
  end
end
