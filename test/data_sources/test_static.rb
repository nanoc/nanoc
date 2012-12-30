# encoding: utf-8

class Nanoc::DataSources::StaticTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def new_data_source(params=nil)
    # Mock site
    site = Nanoc::Site.new({})

    # Create data source
    data_source = Nanoc::DataSources::Static.new(site, nil, nil, params)

    # Done
    data_source
  end

  def test_items
    # Create data source
    data_source = new_data_source(:prefix => 'foo')

    # Create sample files
    FileUtils.mkdir_p('foo')
    FileUtils.mkdir_p('foo/a/b')
    File.open('foo/bar.png',   'w') { |io| io.write("random binary data") }
    File.open('foo/b.c.css',   'w') { |io| io.write("more binary data") }
    File.open('foo/a/b/c.gif', 'w') { |io| io.write("yet more binary data") }

    # Get expected and actual output
    expected_out = [
      Nanoc::Item.new(
        'foo/bar.png',
        { :extension => 'png', :filename => 'foo/bar.png' },
        '/bar.png/',
        :binary => true,
        :mtime => File.mtime('foo/bar.png'),
        :checksum => Pathname.new('foo/bar.png').checksum
      ),
      Nanoc::Item.new(
        'foo/b.c.css',
        { :extension => 'css', :filename => 'foo/b.c.css' },
        '/b.c.css/',
        :binary => true,
        :mtime => File.mtime('foo/b.c.css'),
        :checksum => Pathname.new('foo/b.c.css').checksum
      ),
      Nanoc::Item.new(
        'foo/a/b/c.gif',
        { :extension => 'gif', :filename => 'foo/a/b/c.gif' },
        '/a/b/c.gif/',
        :binary => true,
        :mtime => File.mtime('foo/a/b/c.gif'),
        :checksum => Pathname.new('foo/a/b/c.gif').checksum
      )
    ].sort_by { |i| i.identifier }

    actual_out = data_source.send(:items).sort_by { |i| i.identifier }

    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].raw_content, actual_out[i].raw_content, 'content must match'
      assert_equal expected_out[i].identifier, actual_out[i].identifier, 'identifier must match'
      assert_equal expected_out[i].mtime, actual_out[i].mtime, 'mtime must match'
      assert_equal expected_out[i].raw_filename, actual_out[i].raw_filename, 'file paths must match'
    end
  end
end
