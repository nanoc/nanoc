# frozen_string_literal: true

describe Nanoc::Checking::Checks::InternalLinks do
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

  # FIXME: deduplicate
  def path_to_file_uri(path, dir)
    output_dir = dir.is_a?(String) ? dir : dir.config.output_dir
    output_dir += '/' unless output_dir.end_with?('/')

    uri = Addressable::URI.convert_path(output_dir) + Addressable::URI.convert_path(path)
    uri.to_s
  end

  it 'detects non-broken links' do
    File.write('output/foo.xhtml', '<a href="/bar.html">not broken</a>')
    File.write('output/bar.html', '<a href="/foo.xhtml">not broken</a>')

    check.run
    expect(check.issues).to be_empty
  end

  it 'detects broken links' do
    File.write('output/foo.html', '<a href="/broken">broken</a>')

    check.run
    expect(check.issues).not_to be_empty
  end

  it 'detects broken links in <link>s' do
    File.write('output/bar.html', '<link rel="stylesheet" href="/styledinges.css">')

    check.run
    expect(check.issues.size).to eq(1)
  end

  it 'handles all sorts of path types' do
    FileUtils.mkdir_p('output/stuff')
    File.write('output/origin',     'hi')
    File.write('output/foo',        'hi')
    File.write('output/stuff/blah', 'hi')

    expect(check.send(:valid?, path_to_file_uri('foo', site),         'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('origin', site),      'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('stuff/blah', site),  'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/foo', site),        'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/origin', site),     'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/stuff/blah', site), 'output/origin')).to be(true)
  end

  it 'ignores query strings' do
    FileUtils.mkdir_p('output/stuff')
    File.write('output/stuff/right', 'hi')

    expect(check.send(:valid?, '/stuff/right?foo=123', 'output/origin')).to be(true)
    expect(check.send(:valid?, 'stuff/right?foo=456', 'output/origin')).to be(true)
    expect(check.send(:valid?, 'stuff/wrong?foo=123', 'output/origin')).to be(false)
  end

  it 'handles excludes' do
    site.config.update(checks: { internal_links: { exclude: ['^/excluded\d+'] } })

    expect(check.send(:valid?, path_to_file_uri('/excluded1', site), 'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/excluded2', site), 'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/excluded_not', site), 'output/origin')).to be(false)
  end

  it 'handles exclude targets' do
    site.config.update(checks: { internal_links: { exclude_targets: ['^/excluded\d+'] } })

    expect(check.send(:valid?, path_to_file_uri('/excluded1', site), 'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/excluded2/two', site), 'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/excluded_not', site), 'output/origin')).to be(false)
  end

  it 'handles exclude origins' do
    site.config.update(checks: { internal_links: { exclude_origins: ['^/excluded'] } })

    expect(check.send(:valid?, path_to_file_uri('/foo', site), 'output/excluded')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('/foo', site), 'output/not_excluded')).to be(false)
  end

  it 'unescapes properly' do
    FileUtils.mkdir_p('output/stuff')
    File.write('output/stuff/right foo', 'hi')

    expect(check.send(:valid?, path_to_file_uri('stuff/right%20foo', site), 'output/origin')).to be(true)
    expect(check.send(:valid?, path_to_file_uri('stuff/wrong%20foo', site), 'output/origin')).to be(false)
  end

  it 'handles nested paths' do
    FileUtils.mkdir_p('output/one/two/three')
    File.write('output/one/two/three/a.html', '<a href="../../b.html">b</a>')
    File.write('output/one/b.html', '<a href="two/three/a.html">a</a>')
    File.write('output/one/c.html', '<a href="../one/c.html">c</a>')

    check.run

    expect(check.issues).to be_empty
  end

  it 'ignores protocol-relative URLs' do
    # Protocol-relative URLs are not internal links.

    File.write('output/a.html', '<a href="//example.com/broken">broken</a>')

    check.run

    expect(check.issues).to be_empty
  end
end
