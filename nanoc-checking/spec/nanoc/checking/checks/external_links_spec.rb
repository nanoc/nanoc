# frozen_string_literal: true

describe Nanoc::Checking::Checks::ExternalLinks do
  let(:check) do
    described_class.create(site).tap do |c|
      def c.request_url_once(_url)
        Net::HTTPResponse.new('1.1', '200', 'okay')
      end
    end
  end

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

  around do |ex|
    FileUtils.mkdir('site with spaces')
    Dir.chdir('site with spaces') do
      ex.run
    end
  end

  before do
    FileUtils.mkdir_p('output')
    File.write('Rules', 'passthrough "/**/*"')
  end

  context 'found' do
    before do
      File.write('output/hi.html', '<a href="http://example.com/x">stuff</a>')
    end

    let(:check) do
      described_class.create(site).tap do |c|
        def c.request_url_once(_url)
          Net::HTTPResponse.new('1.1', '200', 'okay')
        end
      end
    end

    it 'has no issues' do
      check.run
      expect(check.issues).to be_empty
    end
  end

  context 'not found' do
    before do
      File.write('output/hi.html', '<a href="http://example.com/x">stuff</a>')
    end

    let(:check) do
      described_class.create(site).tap do |c|
        def c.request_url_once(_url)
          Net::HTTPResponse.new('1.1', '404', 'okay')
        end
      end
    end

    it 'has issues' do
      check.run
      expect(check.issues.size).to eq(1)
    end
  end

  context 'redirect' do
    before do
      skip 'Known failure on Windows' if Nanoc::Core.on_windows?
      File.write('output/hi.html', '<a href="http://example.com/x">stuff</a>')
    end

    let(:check) do
      described_class.create(site).tap do |c|
        # rubocop:disable RSpec/InstanceVariable
        def c.request_url_once(_url)
          @enum ||= Enumerator.new do |y|
            y << Net::HTTPResponse.new('1.1', '302', 'look elsewhere').tap do |h|
              h['Location'] = 'http://elsewhere.example.com/'
            end
            y << Net::HTTPResponse.new('1.1', '200', 'okay')
          end
          @enum.next
        end
        # rubocop:enable RSpec/InstanceVariable
      end
    end

    it 'has no issues' do
      check.run
      expect(check.issues).to be_empty
    end
  end

  context 'redirect without location' do
    before do
      skip 'Known failure on Windows' if Nanoc::Core.on_windows?
      File.write('output/hi.html', '<a href="http://example.com/x">stuff</a>')
    end

    let(:check) do
      described_class.create(site).tap do |c|
        # rubocop:disable RSpec/InstanceVariable
        def c.request_url_once(_url)
          @enum ||= Enumerator.new do |y|
            y << Net::HTTPResponse.new('1.1', '302', 'look elsewhere')
          end
          @enum.next
        end
        # rubocop:enable RSpec/InstanceVariable
      end
    end

    it 'has issues' do
      check.run
      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description)
        .to eq('broken reference to <http://example.com/x>: redirection without a target location')
    end
  end

  context 'invalid URL component' do
    before do
      skip 'Known failure on Windows' if Nanoc::Core.on_windows?
      File.write('output/hi.html', '<a href="mailto:lol">stuff</a>')
    end

    let(:check) do
      described_class.create(site)
    end

    it 'has issues' do
      check.run
      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description)
        .to eq('broken reference to <mailto:lol>: invalid URI')
    end
  end

  context 'javascript URL' do
    before do
      File.write('output/hi.html', %[<a href="javascript:window.scrollTo({top:0,behavior: 'smooth'})">scroll to top</a>])
    end

    let(:check) do
      described_class.create(site)
    end

    it 'has no issues' do
      check.run
      expect(check.issues.size).to eq(0)
    end
  end

  context 'with some patterns excluded' do
    let(:config) do
      super().merge(
        checks: { external_links: { exclude: ['^http://excluded.com'] } },
      )
    end

    let(:check) do
      described_class.create(site)
    end

    before do
      File.write('output/hi.html', <<~CONTENT)
        <a href="http://excluded.com/eggs_clused">eggs clused</a>
        <a href="http://localhost:1234/ink_luded">ink luded</a>
      CONTENT
    end

    it 'has only issues for non-excluded links' do
      VCR.use_cassette('external_links_some_patterns_excluded') do
        check.run
      end

      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description)
        .to match(%r{broken reference to <http://localhost:1234/ink_luded>: Failed to open TCP connection})
    end
  end

  context 'with some files excluded' do
    let(:config) do
      super().merge(
        checks: { external_links: { exclude_files: ['excluded'] } },
      )
    end

    let(:check) do
      described_class.create(site)
    end

    before do
      File.write(
        'output/excluded.html',
        '<a href="http://localhost:1234/eggs_cluded">eggs cluded</a>',
      )

      File.write(
        'output/included.html',
        '<a href="http://example.com/ink_luded">ink luded</a>',
      )
    end

    it 'has only issues for non-excluded files' do
      VCR.use_cassette('external_links_some_files_excluded') do
        check.run
      end

      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description)
        .to match(%r{broken reference to <http://example.com/ink_luded>: 404})
    end
  end
end
