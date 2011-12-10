# encoding: utf-8

class Nanoc::DataSources::FilesystemTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  class SampleFilesystemDataSource < Nanoc::DataSource
    include Nanoc::DataSources::Filesystem
  end

  def test_setup
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Remove files to make sure they are recreated
    FileUtils.rm_rf('content')
    FileUtils.rm_rf('layouts/default')
    FileUtils.rm_rf('lib')

    # Mock VCS
    vcs = mock
    vcs.expects(:add).times(2) # One time for each directory
    data_source.vcs = vcs

    # Recreate files
    data_source.setup

    # Ensure essential files have been recreated
    assert(File.directory?('content/'))
    assert(File.directory?('layouts/'))

    # Ensure no non-essential files have been recreated
    assert(!File.file?('content/index.html'))
    assert(!File.file?('layouts/default.html'))
    refute(File.directory?('lib/'))
  end

  def test_items
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:load_objects).with('content', 'item', Nanoc::Item)
    data_source.items
  end

  def test_layouts
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:load_objects).with('layouts', 'layout', Nanoc::Layout)
    data_source.layouts
  end

  def test_create_item
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:create_object).with('content', 'the content', 'the attributes', 'the identifier', {})
    data_source.create_item('the content', 'the attributes', 'the identifier')
  end

  def test_create_layout
    # Create data source
    data_source = SampleFilesystemDataSource.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:create_object).with('layouts', 'the content', 'the attributes', 'the identifier', {})
    data_source.create_layout('the content', 'the attributes', 'the identifier')
  end

  def test_all_split_files_in_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Write sample files
    FileUtils.mkdir_p('foo')
    %w( foo.html foo.yaml bar.entry.html foo/qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Write stray files
    %w( foo.html~ foo.yaml.orig bar.entry.html.bak ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Get all files
    output_expected = {
      './foo'       => [ 'yaml', 'html' ],
      './bar.entry' => [ nil,    'html' ],
      './foo/qux'   => [ 'yaml', nil    ]
    }
    output_actual = data_source.send :all_split_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_split_files_in_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    FileUtils.mkdir_p('foo')
    %w( foo.html foo.yaml bar.html.erb foo/qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Write stray files
    %w( foo.html~ foo.yaml.orig bar.entry.html.bak ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Get all files
    output_expected = {
      './foo'       => [ 'yaml', 'html'     ],
      './bar'       => [ nil,    'html.erb' ],
      './foo/qux'   => [ 'yaml', nil        ]
    }
    output_actual = data_source.send :all_split_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_split_files_in_with_multiple_dirs
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    %w( aaa/foo.html bbb/foo.html ccc/foo.html ).each do |filename|
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    expected = {
      './aaa/foo' => [ nil, 'html' ],
      './bbb/foo' => [ nil, 'html' ],
      './ccc/foo' => [ nil, 'html' ]
    }
    assert_equal expected, data_source.send(:all_split_files_in, '.')
  end

  def test_all_split_files_in_with_multiple_content_files
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    %w( foo.html foo.xhtml foo.txt foo.yaml bar.html qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    assert_raises RuntimeError do
      data_source.send(:all_split_files_in, '.')
    end
  end

  def test_basename_of_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Get input and expected output
    expected = {
      '/'                 => '/',
      '/foo'              => '/foo',
      '/foo.html'         => '/foo',
      '/foo.xyz.html'     => '/foo.xyz',
      '/foo/'             => '/foo/',
      '/foo.xyz/'         => '/foo.xyz/',
      '/foo/bar'          => '/foo/bar',
      '/foo/bar.html'     => '/foo/bar',
      '/foo/bar.xyz.html' => '/foo/bar.xyz',
      '/foo/bar/'         => '/foo/bar/',
      '/foo/bar.xyz/'     => '/foo/bar.xyz/',
      '/foo.xyz/bar.xyz/' => '/foo.xyz/bar.xyz/'
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:basename_of, input)
      assert_equal(
        expected_output, actual_output,
        "basename_of(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_basename_of_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Get input and expected output
    expected = {
      '/'                 => '/',
      '/foo'              => '/foo',
      '/foo.html'         => '/foo',
      '/foo.xyz.html'     => '/foo',
      '/foo/'             => '/foo/',
      '/foo.xyz/'         => '/foo.xyz/',
      '/foo/bar'          => '/foo/bar',
      '/foo/bar.html'     => '/foo/bar',
      '/foo/bar.xyz.html' => '/foo/bar',
      '/foo/bar/'         => '/foo/bar/',
      '/foo/bar.xyz/'     => '/foo/bar.xyz/',
      '/foo.xyz/bar.xyz/' => '/foo.xyz/bar.xyz/'
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:basename_of, input)
      assert_equal(
        expected_output, actual_output,
        "basename_of(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_ext_of_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Get input and expected output
    expected = {
      '/'                 => '',
      '/foo'              => '',
      '/foo.html'         => '.html',
      '/foo.xyz.html'     => '.html',
      '/foo/'             => '',
      '/foo.xyz/'         => '',
      '/foo/bar'          => '',
      '/foo/bar.html'     => '.html',
      '/foo/bar.xyz.html' => '.html',
      '/foo/bar/'         => '',
      '/foo/bar.xyz/'     => '',
      '/foo.xyz/bar.xyz/' => ''
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:ext_of, input)
      assert_equal(
        expected_output, actual_output,
        "basename_of(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_ext_of_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Get input and expected output
    expected = {
      '/'                 => '',
      '/foo'              => '',
      '/foo.html'         => '.html',
      '/foo.xyz.html'     => '.xyz.html',
      '/foo/'             => '',
      '/foo.xyz/'         => '',
      '/foo/bar'          => '',
      '/foo/bar.html'     => '.html',
      '/foo/bar.xyz.html' => '.xyz.html',
      '/foo/bar/'         => '',
      '/foo/bar.xyz/'     => '',
      '/foo.xyz/bar.xyz/' => ''
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:ext_of, input)
      assert_equal(
        expected_output, actual_output,
        "basename_of(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_parse_embedded_invalid_2
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    assert_raises(RuntimeError) do
      data_source.instance_eval { parse('test.html', nil, 'foobar') }
    end
  end

  def test_parse_embedded_separators_but_not_metadata
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "blah blah\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal(File.read('test.html'), result[1])
    assert_equal({},                     result[0])
  end

  def test_parse_embedded_full_meta
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "foo: bar\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal({ 'foo' => 'bar' }, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_embedded_with_extra_spaces
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----             \n"
      io.write "foo: bar\n"
      io.write "-----\t\t\t\t\t\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal({ 'foo' => 'bar' }, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_embedded_empty_meta
    # Create a file
    File.open('test.html', 'w') do |io|
      io.write "-----\n"
      io.write "-----\n"
      io.write "blah blah\n"
    end

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal({}, result[0])
    assert_equal('blah blah', result[1])
  end

  def test_parse_utf8_bom
    File.open('test.html', 'w') do |io|
      io.write [ 0xEF, 0xBB, 0xBF ].map { |i| i.chr }.join
      io.write "-----\n"
      io.write "utf8bomawareness: high\n"
      io.write "-----\n"
      io.write "content goes here\n"
    end

    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal({ 'utf8bomawareness' => 'high' }, result[0])
    assert_equal('content goes here', result[1])
  end

  def test_parse_embedded_no_meta
    content = "blah\n" \
      "blah blah blah\n" \
      "blah blah\n"

    # Create a file
    File.open('test.html', 'w') { |io| io.write(content) }

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal({}, result[0])
    assert_equal(content, result[1])
  end

  def test_parse_embedded_diff
    content = \
      "--- a/foo\n" \
      "+++ b/foo\n" \
      "blah blah\n"

    # Create a file
    File.open('test.html', 'w') { |io| io.write(content) }

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', nil, 'foobar') }
    assert_equal({}, result[0])
    assert_equal(content, result[1])
  end

  def test_parse_external
    # Create a file
    File.open('test.html', 'w') { |io| io.write("blah blah") }
    File.open('test.yaml', 'w') { |io| io.write("foo: bar") }

    # Create data source
    data_source = Nanoc::DataSources::FilesystemCombined.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', 'test.yaml', 'foobar') }
    assert_equal({ "foo" => "bar"}, result[0])
    assert_equal("blah blah",       result[1])
  end

end
