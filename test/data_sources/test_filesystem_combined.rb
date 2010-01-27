# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemCombinedTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_create_object_not_at_root
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)
    data_source.send(:create_object, 'foobar', 'content here', { :foo => 'bar' }, '/asdf/')

    # Check file existance
    assert File.directory?('foobar')
    assert !File.directory?('foobar/content')
    assert !File.directory?('foobar/asdf')
    assert File.file?('foobar/asdf.html')

    # Check file content
    expected = "--- \nfoo: bar\n\n---\ncontent here"
    assert_equal expected, File.read('foobar/asdf.html')
  end

  def test_create_object_at_root
    # Create item
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)
    data_source.send(:create_object, 'foobar', 'content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('foobar')
    assert !File.directory?('foobar/index')
    assert !File.directory?('foobar/foobar')
    assert File.file?('foobar/index.html')

    # Check file content
    expected = "--- \nfoo: bar\n\n---\ncontent here"
    assert_equal expected, File.read('foobar/index.html')
  end

  def test_files
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Create test files
    FileUtils.mkdir_p('foo')
    FileUtils.mkdir_p('foo/a/b')
    File.open('foo/bar.html',       'w') { |io| io.write('test') }
    File.open('foo/baz.html',       'w') { |io| io.write('test') }
    File.open('foo/a/b/c.html',     'w') { |io| io.write('test') }
    File.open('foo/ugly.html~',     'w') { |io| io.write('test') }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write('test') }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write('test') }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write('test') }

    # Get expected and actual output
    expected_out = [ 'foo/a/b/c.html', 'foo/bar.html', 'foo/baz.html' ]
    actual_out   = data_source.instance_eval { files('foo') }.sort

    # Check
    assert_equal(expected_out, actual_out)
  end

  def test_parse_file_full_meta
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "foo: bar\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse_file('test.html', 'foobar') }
    assert_equal({ 'foo' => 'bar' }, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_file_empty_meta
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse_file('test.html', 'foobar') }
    assert_equal({}, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_file_no_meta
    content = "blah\n" \
      "blah blah blah\n" \
      "blah blah\n"
    # Create a file
    File.open('test.html', 'w') { |io| io.write(content) }

    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse_file('test.html', 'foobar') }
    assert_equal({}, result[0])
    assert_equal(content, result[1])
  end

  def test_load_objects
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Create a fake class
    klass = Class.new do
      attr_reader :stuff
      def initialize(*stuff)
        @stuff = stuff
      end
      def ==(other)
        @stuff == other.stuff
      end
    end

    # Create sample files
    FileUtils.mkdir_p('foo')
    FileUtils.mkdir_p('foo/a/b')
    File.open('foo/bar.html',       'w') { |io| io.write("---\nnum: 1\n---\ntest 1") }
    File.open('foo/b.c.html',       'w') { |io| io.write("---\nnum: 2\n---\ntest 2") }
    File.open('foo/a/b/c.html',     'w') { |io| io.write("---\nnum: 3\n---\ntest 3") }
    File.open('foo/ugly.html~',     'w') { |io| io.write("---\nnum: 4\n---\ntest 4") }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write("---\nnum: 5\n---\ntest 5") }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write("---\nnum: 6\n---\ntest 6") }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write("---\nnum: 7\n---\ntest 7") }

    # Get expected and actual output
    expected_out = [
      klass.new(
        'test 1',
        { 'num' => 1, :filename => 'foo/bar.html',   :extension => 'html', :file => File.open('foo/bar.html') },
        '/bar/',
        File.mtime('foo/bar.html')
      ),
      klass.new(
        'test 2',
        { 'num' => 2, :filename => 'foo/b.c.html',   :extension => 'html', :file => File.open('foo/b.c.html') },
        '/b/',
        File.mtime('foo/b.c.html')
      ),
      klass.new(
        'test 3',
        { 'num' => 3, :filename => 'foo/a/b/c.html', :extension => 'html', :file => File.open('foo/a/b/c.html') },
        '/a/b/c/',
        File.mtime('foo/a/b/c.html')
      )
    ]
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[0] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      assert_equal expected_out[i].stuff[3], actual_out[i].stuff[3], 'mtime must match'
      assert_equal expected_out[i].stuff[1][:file].path, actual_out[i].stuff[1][:file].path, 'file paths must match'
      [ 'num', :filename, :extension ].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_filename_to_identifier_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Get expected and actual output
    expected_out = [
      '/x/',
      '/x/',
      '/x/'
    ]
    actual_out = [
      data_source.send(:filename_to_identifier, 'foo/x',            'foo'),
      data_source.send(:filename_to_identifier, 'foo/x.html',       'foo'),
      data_source.send(:filename_to_identifier, 'foo/x.entry.html', 'foo')
    ]

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i], actual_out[i]
    end
  end

  def test_filename_to_identifier_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCombined.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Get expected and actual output
    expected_out = [
      '/x/',
      '/x/',
      '/x.entry/'
    ]
    actual_out = [
      data_source.send(:filename_to_identifier, 'foo/x',            'foo'),
      data_source.send(:filename_to_identifier, 'foo/x.html',       'foo'),
      data_source.send(:filename_to_identifier, 'foo/x.entry.html', 'foo')
    ]

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i], actual_out[i]
    end
  end

end
