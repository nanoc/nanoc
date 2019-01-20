# frozen_string_literal: true

describe ::Nanoc::Checking::Checks::ExternalLinks do
  let(:check) do
    Nanoc::Checking::Checks::ExternalLinks.create(site).tap do |c|
      def c.request_url_once(_url)
        Net::HTTPResponse.new('1.1', '200', 'okay')
      end
    end
  end

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      code_snippets: code_snippets,
      data_source: Nanoc::Int::InMemDataSource.new(items, layouts),
    )
  end

  let(:config)        { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }
  let(:code_snippets) { [] }
  let(:items)         { Nanoc::Core::ItemCollection.new(config, []) }
  let(:layouts)       { Nanoc::Core::LayoutCollection.new(config, []) }

  before do
    FileUtils.mkdir_p('output')
    File.write('output/hi.html', '<a href="http://example.com/x">stuff</a>')
    File.write('Rules', 'passthrough "/**/*"')
  end

  context 'found' do
    let(:check) do
      Nanoc::Checking::Checks::ExternalLinks.create(site).tap do |c|
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
    let(:check) do
      Nanoc::Checking::Checks::ExternalLinks.create(site).tap do |c|
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
      skip 'Known failure on Windows' if Nanoc.on_windows?
    end

    let(:check) do
      Nanoc::Checking::Checks::ExternalLinks.create(site).tap do |c|
        def c.request_url_once(_url)
          @enum ||= Enumerator.new do |y|
            y << Net::HTTPResponse.new('1.1', '302', 'look elsewhere').tap do |h|
              h['Location'] = 'http://elsewhere.example.com/'
            end
            y << Net::HTTPResponse.new('1.1', '200', 'okay')
          end
          @enum.next
        end
      end
    end

    it 'has no issues' do
      check.run
      expect(check.issues).to be_empty
    end
  end

  context 'redirect without location' do
    before do
      skip 'Known failure on Windows' if Nanoc.on_windows?
    end

    let(:check) do
      Nanoc::Checking::Checks::ExternalLinks.create(site).tap do |c|
        def c.request_url_once(_url)
          @enum ||= Enumerator.new do |y|
            y << Net::HTTPResponse.new('1.1', '302', 'look elsewhere')
          end
          @enum.next
        end
      end
    end

    it 'has issues' do
      check.run
      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description)
        .to eq('broken reference to http://example.com/x: redirection without a target location')
    end
  end

  context 'invalid URL component' do
    before do
      skip 'Known failure on Windows' if Nanoc.on_windows?
    end

    let(:check) do
      Nanoc::Checking::Checks::ExternalLinks.create(site)
    end

    before do
      File.write('output/hi.html', '<a href="mailto:lol">stuff</a>')
    end

    it 'has issues' do
      check.run
      expect(check.issues.size).to eq(1)
      expect(check.issues.first.description)
        .to eq('broken reference to mailto:lol: invalid URI')
    end
  end
end
