# frozen_string_literal: true

describe 'GH-1045', site: true, stdio: true do
  before do
    File.write('content/foo.txt', 'foo')
    FileUtils.touch('content/foo.txt', mtime: Time.parse('2015-03-02 10:00:00Z'))

    File.write('content/sitemap.erb', '<%= xml_sitemap(items: items.select { |i| i.path.end_with?(\'/\') }) %>')

    File.write('nanoc.yaml', <<~EOS)
      base_url: 'http://example.com'
EOS

    File.write('lib/default.rb', <<~EOS)
      include Nanoc::Helpers::XMLSitemap
EOS

    File.write('Rules', <<~EOS)
      compile '/*.txt' do
        write item.identifier.without_ext + '/index.html'
      end

      compile '/sitemap.erb' do
        filter :erb
        write item.identifier.without_ext + '.xml'
      end
EOS
  end

  it 'creates the sitemap' do
    Nanoc::CLI.run(%w[compile])

    expect(File.file?('output/sitemap.xml')).to be
    contents = File.read('output/sitemap.xml')
    expect(contents).to match(%r{<loc>http://example.com/foo/</loc>})
    expect(contents).to match(%r{<lastmod>2015-03-02</lastmod>})
  end

  it 'updates the sitemap' do
    Nanoc::CLI.run(%w[compile])
    File.write('content/foo.txt', 'foo 2')
    FileUtils.touch('content/foo.txt', mtime: Time.parse('2016-04-03 10:00:00Z'))
    Nanoc::CLI.run(%w[compile])

    expect(File.file?('output/sitemap.xml')).to be
    contents = File.read('output/sitemap.xml')
    expect(contents).to match(%r{<loc>http://example.com/foo/</loc>})
    expect(contents).to match(%r{<lastmod>2016-04-03</lastmod>})
  end
end
