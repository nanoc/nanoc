# frozen_string_literal: true

describe Nanoc::Checking::Checks::MixedContent do
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

  def create_output_file(name, lines)
    FileUtils.mkdir_p('output')
    File.write('output/' + name, lines.join('\n'))
  end

  it 'handles HTTPS URLs' do
    create_output_file('foo.html', [
      '<img src="https://nanoc.app/logo.png" />',
      '<img src="https://nanoc.app/logo.png" />',
      '<link href="https://nanoc.app/style.css" />',
      '<script src="https://nanoc.app/app.js"></script>',
      '<form action="https://nanoc.app/process.cgi"></form>',
      '<iframe src="https://nanoc.app/preview.html"></iframe>',
      '<audio src="https://nanoc.app/theme-song.flac"></audio>',
      '<video src="https://nanoc.app/screen-cast.mkv"></video>',
    ])

    check.run
    expect(check.issues).to be_empty
  end

  it 'handles absolute paths' do
    create_output_file('foo.html', [
      '<img src="/logo.png" />',
      '<link href="/style.css" />',
      '<script src="/app.js"></script>',
      '<form action="/process.cgi"></form>',
      '<iframe src="/preview.html"></iframe>',
      '<audio src="/theme-song.flac"></audio>',
      '<video src="/screen-cast.mkv"></video>',
    ])

    check.run
    expect(check.issues).to be_empty
  end

  it 'handles protocol-relative paths' do
    create_output_file('foo.html', [
      '<img src="//nanoc.ws/logo.png" />',
      '<link href="//nanoc.ws/style.css" />',
      '<script src="//nanoc.ws/app.js"></script>',
      '<form action="//nanoc.ws/process.cgi"></form>',
      '<iframe src="//nanoc.ws/preview.html"></iframe>',
      '<audio src="//nanoc.ws/theme-song.flac"></audio>',
      '<video src="//nanoc.ws/screen-cast.mkv"></video>',
    ])

    check.run
    expect(check.issues).to be_empty
  end

  it 'handles relative paths' do
    create_output_file('foo.html', [
      '<img src="logo.png" />',
      '<link href="style.css" />',
      '<script src="app.js"></script>',
      '<form action="process.cgi"></form>',
      '<iframe src="preview.html"></iframe>',
      '<audio src="theme-song.flac"></audio>',
      '<video src="screen-cast.mkv"></video>',
    ])

    check.run
    expect(check.issues).to be_empty
  end

  it 'ignores query strings' do
    create_output_file('foo.html', [
      '<img src="?query-string" />',
      '<link href="?query-string" />',
      '<script src="?query-string"></script>',
      '<form action="?query-string"></form>',
      '<iframe src="?query-string"></iframe>',
      '<audio src="?query-string"></audio>',
      '<video src="?query-string"></video>',
    ])

    check.run
    expect(check.issues).to be_empty
  end

  it 'ignores fragments' do
    create_output_file('foo.html', [
      '<img src="#fragment" />',
      '<link href="#fragment" />',
      '<script src="#fragment"></script>',
      '<form action="#fragment"></form>',
      '<iframe src="#fragment"></iframe>',
      '<audio src="#fragment"></audio>',
      '<video src="#fragment"></video>',
    ])

    check.run
    expect(check.issues).to be_empty
  end

  it 'handles HTTP URLs' do
    create_output_file('foo.html', [
      '<img src="HTTP://nanoc.ws/logo.png" />',
      '<link href="http://nanoc.ws/style.css" />',
      '<script src="http://nanoc.ws/app.js"></script>',
      '<form action="http://nanoc.ws/process.cgi"></form>',
      '<iframe src="http://nanoc.ws/preview.html"></iframe>',
      '<audio src="http://nanoc.ws/theme-song.flac"></audio>',
      '<video src="http://nanoc.ws/screencast.mkv"></video>',
    ])

    check.run
    issues = check.issues.to_a
    expect(issues.count).to eq(7)

    descriptions = issues.map(&:description)
    expect(issues.map(&:subject)).to all(eq('output/foo.html'))

    expect(descriptions).to include('mixed content include: http://nanoc.ws/logo.png')
    expect(descriptions).to include('mixed content include: http://nanoc.ws/style.css')
    expect(descriptions).to include('mixed content include: http://nanoc.ws/app.js')
    expect(descriptions).to include('mixed content include: http://nanoc.ws/process.cgi')
    expect(descriptions).to include('mixed content include: http://nanoc.ws/preview.html')
    expect(descriptions).to include('mixed content include: http://nanoc.ws/theme-song.flac')
    expect(descriptions).to include('mixed content include: http://nanoc.ws/screencast.mkv')

    expect(descriptions).not_to include('mixed content include: HTTP://nanoc.ws/logo.png')
  end

  it 'ignores inert content' do
    create_output_file('foo.html', [
      '<a href="http://nanoc.ws">The homepage</a>',
      '<a name="Not a link">Content</a>',
      '<script>// inline JavaScript</script>',
      '<img href="http://nanoc.ws/logo.png" />',
      '<link src="http://nanoc.ws/style.css" />',
      '<script href="http://nanoc.ws/app.js"></script>',
      '<form src="http://nanoc.ws/process.cgi"></form>',
      '<iframe href="http://nanoc.ws/preview.html"></iframe>',
      '<audio href="http://nanoc.ws/theme-song.flac"></audio>',
      '<video target="http://nanoc.ws/screen-cast.mkv"></video>',
      '<p>http://nanoc.ws/harmless-text</p>',
    ])

    check.run
    expect(check.issues).to be_empty
  end
end
