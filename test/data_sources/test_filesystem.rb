# encoding: utf-8

class Nanoc::DataSources::FilesystemTest < Nanoc::TestCase

  def setup
    super

    @old_pwd = Dir.getwd
    create_site_here
    site = Nanoc::SiteLoader.new.load
    FileUtils.cd('content')
    config = Nanoc::SiteLoader::DEFAULT_DATA_SOURCE_CONFIG
    @data_source = Nanoc::DataSources::Filesystem.new(site, nil, nil, config)
  end

  def teardown
    FileUtils.cd(@old_pwd)

    super
  end

  def test_all_base_filenames_in
    File.write('index.html',        'x')
    File.write('reviews.html',      'x')
    File.write('reviews.html.yaml', 'x')
    File.write('meta.yaml',         'x')

    expected_filenames = %w( ./index.html ./reviews.html ./meta ).sort
    actual_filenames   = @data_source.send(:all_base_filenames_in, '.').sort

    assert_equal(expected_filenames, actual_filenames)
  end

  def test_all_base_filenames_in_without_stray_files
    FileUtils.mkdir_p('foo')
    File.write('foo/ugly.html',      'stuff')
    File.write('foo/ugly.html~',     'stuff')
    File.write('foo/ugly.html.orig', 'stuff')
    File.write('foo/ugly.html.rej',  'stuff')
    File.write('foo/ugly.html.bak',  'stuff')

    expected_filenames = %w( ./foo/ugly.html )
    actual_filenames   = @data_source.send(:all_base_filenames_in, '.')

    assert_equal(expected_filenames, actual_filenames)
  end

  def test_binary_extension?
    assert @data_source.send(:binary_extension?, 'foo')
    refute @data_source.send(:binary_extension?, 'txt')
  end

  def test_content_and_attributes_for_file_with_metadata
    filename = 'foo.txt'
    data = "---\nfoo: 123\n---\n\nHello!"
    File.write(filename, data)

    actual_content, actual_attributes =
      @data_source.send(:content_and_attributes_for_file, filename)

    expected_content, expected_attributes =
      "Hello!", { "foo" => 123 }

    assert_equal expected_content, actual_content.string
    assert_equal expected_attributes, actual_attributes
  end

  def test_content_and_attributes_for_file_without_metadata
    filename = 'foo.txt'
    data = "stuff and stuff"
    File.write(filename, data)

    actual_content, actual_attributes =
      @data_source.send(:content_and_attributes_for_file, filename)

    expected_content, expected_attributes =
      data, {}

    assert_equal expected_content, actual_content.string
    assert_equal expected_attributes, actual_attributes
  end

  def test_content_and_attributes_for_file_with_incorrectly_formatted_metadata_section
    filename = 'foo.txt'
    data = "-----\nfoo: 123\n-----\n\nHello!"
    File.write(filename, data)

    actual_content, actual_attributes =
      @data_source.send(:content_and_attributes_for_file, filename)

    expected_content, expected_attributes =
      data, {}

    assert_equal expected_content, actual_content.string
    assert_equal expected_attributes, actual_attributes
  end

  def test_content_and_attributes_for_file_with_not_enough_separators
    filename = 'foo.txt'
    data = "---\nfoo: 123\n-----\n\nHello!"
    File.write(filename, data)

    assert_raises(Nanoc::DataSources::Filesystem::EmbeddedMetadataParseError) do
      @data_source.send(:content_and_attributes_for_file, filename)
    end
  end

  def test_content_and_attributes_for_file_with_invalid_yaml
    filename = 'foo.txt'
    data = "---\nfoo : bar : baz\n---\n\nHello!"
    File.write(filename, data)

    assert_raises(Nanoc::DataSources::Filesystem::CannotParseYAMLError) do
      @data_source.send(:content_and_attributes_for_file, filename)
    end
  end

  def test_content_and_attributes_for_file_with_diff
    filename = 'foo.txt'
    data = "--- a/foo\n" \
      "+++ b/foo\n" \
      "blah blah\n"
    File.write(filename, data)

    actual_content, actual_attributes =
      @data_source.send(:content_and_attributes_for_file, filename)

    expected_content, expected_attributes =
      data, {}

    assert_equal expected_content, actual_content.string
    assert_equal expected_attributes, actual_attributes
  end

  def test_items
    FileUtils.mkdir_p('content')
    File.write('content/foo.html',      'stuff')
    File.write('content/foo.html.yaml', 'ugly: true')

    items = @data_source.items
    assert_equal 1, items.size
    assert_equal 'stuff',        items.first.content.string
    assert_equal '/foo.html',    items.first.identifier.to_s
    assert_equal({ ugly: true }, items.first.attributes)
  end

  def test_items_binary
    FileUtils.mkdir_p('content')
    File.write('content/foo.txt', 'stuff')
    File.write('content/foo.jpg', 'stuff')

    items = @data_source.items
    assert_equal 2, items.size
    refute items.find { |i| i.identifier == '/foo.txt' }.binary?
    assert items.find { |i| i.identifier == '/foo.jpg' }.binary?
  end

  def test_read_default_encoding
    File.write('foo.txt', 'Hëllö')
    assert_equal 'Hëllö', @data_source.read('foo.txt')
  end

  def test_read_other_encoding
    File.write('foo.txt', 'Hëllö'.encode('ISO-8859-1'))

    error = assert_raises(ArgumentError) do
      @data_source.read('foo.txt')
    end
    assert_equal 'invalid byte sequence in UTF-8', error.message

    begin
      @data_source.config[:encoding] = 'ISO-8859-1'
      assert_equal 'Hëllö', @data_source.read('foo.txt')
    ensure
      @data_source.config[:encoding] = 'UTF-8'
    end
  end

  def test_read_utf8_bom
    File.write('test.html', [ 0xEF, 0xBB, 0xBF ].map { |i| i.chr }.join + 'stuff')

    assert_equal 'stuff', @data_source.read('test.html')
  end

  def test_setup
    # Recreate files
    @data_source.setup

    # Ensure essential files have been recreated
    assert(File.directory?('content/'))
    assert(File.directory?('layouts/'))

    # Ensure no non-essential files have been recreated
    assert(!File.file?('content/index.html'))
    assert(!File.file?('layouts/default.html'))
    refute(File.directory?('lib/'))
  end

end
