# frozen_string_literal: true

require 'helper'

class Nanoc::DataSources::FilesystemTest < Nanoc::TestCase
  def new_data_source(params = nil)
    with_site do |site|
      Nanoc::DataSources::Filesystem.new(site.config, nil, nil, params)
    end
  end

  def test_load_objects
    # Create data source
    data_source = new_data_source

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
        { 'num' => 1, :filename => 'foo/bar.html', :extension => 'html', mtime: File.mtime('foo/bar.html') },
        '/bar/',
      ),
      klass.new(
        'test 2',
        { 'num' => 2, :filename => 'foo/b.c.html', :extension => 'c.html', mtime: File.mtime('foo/b.c.html') },
        '/b/',
      ),
      klass.new(
        'test 3',
        { 'num' => 3, :filename => 'foo/a/b/c.html', :extension => 'html', mtime: File.mtime('foo/a/b/c.html') },
        '/a/b/c/',
      ),
    ]
    actual_out = data_source.send(:load_objects, 'foo', klass).sort_by { |i| i.stuff[0].string }

    # Check
    (0..expected_out.size - 1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0].string, 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      ['num', :filename, :extension, :mtime].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_load_objects_with_same_extensions
    # Create data source
    data_source = new_data_source(identifier_type: 'full')

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
    File.open('foo/bar.html', 'w') { |io| io.write("---\nnum: 1\n---\ntest 1") }
    File.open('foo/bar.md',   'w') { |io| io.write("---\nnum: 1\n---\ntest 1") }

    # Check
    actual_out = data_source.send(:load_objects, 'foo', klass)
    assert_equal 2, actual_out.size
  end

  def test_load_binary_objects
    # Create data source
    data_source = new_data_source

    # Create sample files
    FileUtils.mkdir_p('foo')
    File.open('foo/stuff.dat', 'w') { |io| io.write('random binary data') }

    # Load
    items = data_source.send(:load_objects, 'foo', Nanoc::Core::Item)

    # Check
    assert_equal 1, items.size
    assert items[0].content.binary?
    assert_equal "#{Dir.getwd}/foo/stuff.dat", items[0].content.filename
    assert_equal Nanoc::Core::BinaryContent, items[0].content.class
  end

  def test_load_layouts_with_nil_dir_name
    # Create data source
    data_source = new_data_source(layouts_dir: nil)

    # Create sample files
    FileUtils.mkdir_p('layouts')
    File.write('layouts/stuff.txt', 'blah blah')

    # Load
    layouts = data_source.layouts

    # Check
    assert_empty(layouts)
  end

  def test_load_binary_layouts
    # Create data source
    data_source = new_data_source

    # Create sample files
    FileUtils.mkdir_p('foo')
    File.open('foo/stuff.dat', 'w') { |io| io.write('random binary data') }

    # Load
    assert_raises(Nanoc::DataSources::Filesystem::Errors::BinaryLayout) do
      data_source.send(:load_objects, 'foo', Nanoc::Core::Layout)
    end
  end

  def test_identifier_for_filename_with_full_style_identifier
    # Create data source
    data_source = new_data_source(identifier_type: 'full')

    # Get input and expected output
    expected = {
      '/foo' => Nanoc::Identifier.new('/foo', type: :full),
      '/foo.html' => Nanoc::Identifier.new('/foo.html',       type: :full),
      '/foo/index.html' => Nanoc::Identifier.new('/foo/index.html', type: :full),
      '/foo.html.erb' => Nanoc::Identifier.new('/foo.html.erb', type: :full),
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:identifier_for_filename, input)
      assert_equal(
        expected_output, actual_output,
        "identifier_for_filename(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_identifier_for_filename_allowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source(allow_periods_in_identifiers: true)

    # Get input and expected output
    expected = {
      '/foo' => '/foo/',
      '/foo.html' => '/foo/',
      '/foo/index.html' => '/foo/',
      '/foo.entry.html' => '/foo.entry/',
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:identifier_for_filename, input)
      assert_equal(
        expected_output, actual_output,
        "identifier_for_filename(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_identifier_for_filename_disallowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source

    # Get input and expected output
    expected = {
      '/foo' => '/foo/',
      '/foo.html' => '/foo/',
      '/foo/index.html' => '/foo/',
      '/foo.html.erb' => '/foo/',
    }

    # Check
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:identifier_for_filename, input)
      assert_equal(
        expected_output, actual_output,
        "identifier_for_filename(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_identifier_for_filename_with_subfilename_allowing_periods_in_identifiers
    expectations = {
      'foo/bar.yaml' => '/foo/bar/',
      'foo/quxbar.yaml' => '/foo/quxbar/',
      'foo/barqux.yaml' => '/foo/barqux/',
      'foo/quxbarqux.yaml' => '/foo/quxbarqux/',
      'foo/qux.bar.yaml' => '/foo/qux.bar/',
      'foo/bar.qux.yaml' => '/foo/bar.qux/',
      'foo/qux.bar.qux.yaml' => '/foo/qux.bar.qux/',
      'foo/index.yaml' => '/foo/',
      'index.yaml' => '/',
      'foo/blah_index.yaml' => '/foo/blah_index/',
    }

    data_source = new_data_source(allow_periods_in_identifiers: true)
    expectations.each_pair do |meta_filename, expected_identifier|
      content_filename = meta_filename.sub(/yaml$/, 'html')
      [meta_filename, content_filename].each do |filename|
        assert_equal(
          expected_identifier,
          data_source.instance_eval { identifier_for_filename(filename) },
        )
      end
    end
  end

  def test_identifier_for_filename_with_subfilename_disallowing_periods_in_identifiers
    expectations = {
      'foo/bar.yaml' => '/foo/bar/',
      'foo/quxbar.yaml' => '/foo/quxbar/',
      'foo/barqux.yaml' => '/foo/barqux/',
      'foo/quxbarqux.yaml' => '/foo/quxbarqux/',
      'foo/qux.bar.yaml' => '/foo/qux/',
      'foo/bar.qux.yaml' => '/foo/bar/',
      'foo/qux.bar.qux.yaml' => '/foo/qux/',
      'foo/index.yaml' => '/foo/',
      'index.yaml' => '/',
      'foo/blah_index.yaml' => '/foo/blah_index/',
    }

    data_source = new_data_source
    expectations.each_pair do |meta_filename, expected_identifier|
      content_filename = meta_filename.sub(/yaml$/, 'html')
      [meta_filename, content_filename].each do |filename|
        assert_equal(
          expected_identifier,
          data_source.instance_eval { identifier_for_filename(filename) },
        )
      end
    end
  end

  def test_identifier_for_filename_with_index_filenames_allowing_periods_in_identifier
    expected = {
      '/index.html.erb' => '/index.html/',
      '/index.html' => '/',
      '/index' => '/',
      '/foo/index.html.erb' => '/foo/index.html/',
      '/foo/index.html' => '/foo/',
      '/foo/index' => '/foo/',
    }

    data_source = new_data_source(allow_periods_in_identifiers: true)
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:identifier_for_filename, input)
      assert_equal(
        expected_output, actual_output,
        "identifier_for_filename(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_identifier_for_filename_with_index_filenames_disallowing_periods_in_identifier
    expected = {
      '/index.html.erb' => '/',
      '/index.html' => '/',
      '/index' => '/',
      '/foo/index.html.erb' => '/foo/',
      '/foo/index.html' => '/foo/',
      '/foo/index' => '/foo/',
    }

    data_source = new_data_source
    expected.each_pair do |input, expected_output|
      actual_output = data_source.send(:identifier_for_filename, input)
      assert_equal(
        expected_output, actual_output,
        "identifier_for_filename(#{input.inspect}) should equal #{expected_output.inspect}, not #{actual_output.inspect}"
      )
    end
  end

  def test_load_objects_allowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source(allow_periods_in_identifiers: true)

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
    File.open('foo/a/b/c.yaml',     'w') { |io| io.write("---\nnum: 1\n") }
    File.open('foo/b.c.yaml',       'w') { |io| io.write("---\nnum: 2\n") }
    File.open('foo/b.c.html',       'w') { |io| io.write('test 2')        }
    File.open('foo/car.html',       'w') { |io| io.write('test 3')        }
    File.open('foo/ugly.yaml~',     'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html~',     'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write('blah')          }

    # Get expected output
    expected_out = [
      klass.new(
        '',
        {
          'num' => 1,
          :content_filename => nil,
          :meta_filename => 'foo/a/b/c.yaml',
          :extension => nil,
          :file => nil,
          mtime: File.mtime('foo/a/b/c.yaml'),
        },
        '/a/b/c/',
      ),
      klass.new(
        'test 2',
        {
          'num' => 2,
          :content_filename => 'foo/b.c.html',
          :meta_filename => 'foo/b.c.yaml',
          :extension => 'html',
          :file => File.open('foo/b.c.html'),
          mtime: File.mtime('foo/b.c.html') > File.mtime('foo/b.c.yaml') ? File.mtime('foo/b.c.html') : File.mtime('foo/b.c.yaml'),
        },
        '/b.c/',
      ),
      klass.new(
        'test 3',
        {
          content_filename: 'foo/car.html',
          meta_filename: nil,
          extension: 'html',
          file: File.open('foo/car.html'),
          mtime: File.mtime('foo/car.html'),
        },
        '/car/',
      ),
    ]

    # Get actual output ordered by identifier
    actual_out = data_source.send(:load_objects, 'foo', klass).sort_by { |i| i.stuff[2] }

    # Check
    (0..expected_out.size - 1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0].string, 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'

      ['num', :content_filename, :meta_filename, :extension, :mtime].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_load_objects_disallowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source

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
    File.open('foo/a/b/c.yaml',     'w') { |io| io.write("---\nnum: 1\n") }
    File.open('foo/b.yaml',         'w') { |io| io.write("---\nnum: 2\n") }
    File.open('foo/b.html.erb',     'w') { |io| io.write('test 2')        }
    File.open('foo/car.html',       'w') { |io| io.write('test 3')        }
    File.open('foo/ugly.yaml~',     'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html~',     'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write('blah')          }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write('blah')          }

    # Get expected output
    expected_out = [
      klass.new(
        '',
        {
          'num' => 1,
          :content_filename => nil,
          :meta_filename => 'foo/a/b/c.yaml',
          :extension => nil,
          :file => nil,
          mtime: File.mtime('foo/a/b/c.yaml'),
        },
        '/a/b/c/',
      ),
      klass.new(
        'test 2',
        {
          'num' => 2,
          :content_filename => 'foo/b.html.erb',
          :meta_filename => 'foo/b.yaml',
          :extension => 'html.erb',
          :file => File.open('foo/b.html.erb'),
          mtime: File.mtime('foo/b.html.erb') > File.mtime('foo/b.yaml') ? File.mtime('foo/b.html.erb') : File.mtime('foo/b.yaml'),
        },
        '/b/',
      ),
      klass.new(
        'test 3',
        {
          content_filename: 'foo/car.html',
          meta_filename: nil,
          extension: 'html',
          file: File.open('foo/car.html'),
          mtime: File.mtime('foo/car.html'),
        },
        '/car/',
      ),
    ]

    # Get actual output ordered by identifier
    actual_out = data_source.send(:load_objects, 'foo', klass).sort_by { |i| i.stuff[2] }

    # Check
    (0..expected_out.size - 1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0].string, 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'

      ['num', :content_filename, :meta_filename, :extension, :mtime].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_load_objects_correct_identifier_with_separate_yaml_file
    data_source = new_data_source(identifier_type: 'full')

    FileUtils.mkdir_p('foo')
    File.write('foo/donkey.jpeg', 'data')
    File.write('foo/donkey.yaml', "---\nalt: Donkey\n")

    objects = data_source.send(:load_objects, 'foo', Nanoc::Core::Item)
    assert_equal 1, objects.size
    assert_equal '/donkey.jpeg', objects.first.identifier.to_s
  end

  def test_filename_for
    data_source = new_data_source

    assert_equal '/foo.bar',     data_source.send(:filename_for, '/foo', 'bar')
    assert_equal '/foo.bar.baz', data_source.send(:filename_for, '/foo', 'bar.baz')
    assert_equal '/foo',         data_source.send(:filename_for, '/foo', '')
    assert_equal nil,            data_source.send(:filename_for, '/foo', nil)
  end

  def test_compile_iso_8859_1_site
    # Create data source
    data_source = new_data_source

    # Create item
    FileUtils.mkdir_p('content')
    File.open('content/foo.md', 'w') { |io| io << 'Hëllö' }

    # Parse
    begin
      original_default_external_encoding = Encoding.default_external
      Encoding.default_external = 'ISO-8859-1'

      items = data_source.items

      assert_equal 1, items.size
      assert_equal Encoding.find('UTF-8'), items[0].content.string.encoding
    ensure
      Encoding.default_external = original_default_external_encoding
    end
  end

  def test_compile_iso_8859_1_site_with_explicit_encoding
    # Create data source
    data_source = new_data_source({})
    data_source.config[:encoding] = 'ISO-8859-1'

    # Create item
    begin
      original_default_external_encoding = Encoding.default_external
      Encoding.default_external = 'ISO-8859-1'

      FileUtils.mkdir_p('content')
      File.open('content/foo.md', 'w') { |io| io << 'Hëllö' }
    ensure
      Encoding.default_external = original_default_external_encoding
    end

    # Parse
    items = data_source.items
    assert_equal 1, items.size
    assert_equal Encoding.find('UTF-8'), items[0].content.string.encoding
  end

  def test_all_split_files_in_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, allow_periods_in_identifiers: true)

    # Write sample files
    FileUtils.mkdir_p('foo')
    %w[foo.html foo.yaml bar.entry.html foo/qux.yaml].each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Write stray files
    %w[foo.html~ foo.yaml.orig bar.entry.html.bak].each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Get all files
    output_expected = {
      './foo' => ['yaml', ['html']],
      './bar.entry' => [nil, ['html']],
      './foo/qux' => ['yaml', [nil]],
    }
    output_actual = data_source.send :all_split_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_split_files_in_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Write sample files
    FileUtils.mkdir_p('foo')
    %w[foo.html foo.yaml bar.html.erb foo/qux.yaml].each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Write stray files
    %w[foo.html~ foo.yaml.orig bar.entry.html.bak].each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Get all files
    output_expected = {
      './foo' => ['yaml', ['html']],
      './bar' => [nil,    ['html.erb']],
      './foo/qux' => ['yaml', [nil]],
    }
    output_actual = data_source.send :all_split_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_split_files_in_with_multiple_dirs
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Write sample files
    %w[aaa/foo.html bbb/foo.html ccc/foo.html].each do |filename|
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    expected = {
      './aaa/foo' => [nil, ['html']],
      './bbb/foo' => [nil, ['html']],
      './ccc/foo' => [nil, ['html']],
    }
    assert_equal expected, data_source.send(:all_split_files_in, '.')
  end

  def test_all_split_files_in_with_same_extensions
    # Create data source
    config = { identifier_type: 'full' }
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, config)

    # Write sample files
    %w[stuff/foo.html stuff/foo.md stuff/foo.yaml].each do |filename|
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check - { './stuff/foo' => ['yaml', ['html', 'md']] }
    res = data_source.send(:all_split_files_in, '.')
    assert_equal ['./stuff/foo'], res.keys
    assert_equal 2, res.values[0].size
    assert_equal 'yaml', res.values[0][0]
    assert_equal Array, res.values[0][1].class
    assert_equal %w[html md], res.values[0][1].sort
  end

  def test_all_split_files_in_with_multiple_content_files
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Write sample files
    %w[foo.html foo.xhtml foo.txt foo.yaml bar.html qux.yaml].each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    assert_raises(Nanoc::DataSources::Filesystem::Errors::MultipleContentFiles) do
      data_source.send(:all_split_files_in, '.')
    end
  end

  def test_basename_of_with_full_style_identifiers
    # Create data source
    config = { identifier_type: 'full' }
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, config)

    # Get input and expected output
    expected = {
      '/' => '/',
      '/foo' => '/foo',
      '/foo.html' => '/foo',
      '/foo.xyz.html' => '/foo.xyz',
      '/foo/bar' => '/foo/bar',
      '/foo/bar.html' => '/foo/bar',
      '/foo/bar.xyz.html' => '/foo/bar.xyz',
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

  def test_basename_of_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, allow_periods_in_identifiers: true)

    # Get input and expected output
    expected = {
      '/' => '/',
      '/foo' => '/foo',
      '/foo.html' => '/foo',
      '/foo.xyz.html' => '/foo.xyz',
      '/foo/' => '/foo/',
      '/foo.xyz/' => '/foo.xyz/',
      '/foo/bar' => '/foo/bar',
      '/foo/bar.html' => '/foo/bar',
      '/foo/bar.xyz.html' => '/foo/bar.xyz',
      '/foo/bar/' => '/foo/bar/',
      '/foo/bar.xyz/' => '/foo/bar.xyz/',
      '/foo.xyz/bar.xyz/' => '/foo.xyz/bar.xyz/',
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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Get input and expected output
    expected = {
      '/' => '/',
      '/foo' => '/foo',
      '/foo.html' => '/foo',
      '/foo.xyz.html' => '/foo',
      '/foo/' => '/foo/',
      '/foo.xyz/' => '/foo.xyz/',
      '/foo/bar' => '/foo/bar',
      '/foo/bar.html' => '/foo/bar',
      '/foo/bar.xyz.html' => '/foo/bar',
      '/foo/bar/' => '/foo/bar/',
      '/foo/bar.xyz/' => '/foo/bar.xyz/',
      '/foo.xyz/bar.xyz/' => '/foo.xyz/bar.xyz/',
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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, allow_periods_in_identifiers: true)

    # Get input and expected output
    expected = {
      '/' => '',
      '/foo' => '',
      '/foo.html' => '.html',
      '/foo.xyz.html' => '.html',
      '/foo/' => '',
      '/foo.xyz/' => '',
      '/foo/bar' => '',
      '/foo/bar.html' => '.html',
      '/foo/bar.xyz.html' => '.html',
      '/foo/bar/' => '',
      '/foo/bar.xyz/' => '',
      '/foo.xyz/bar.xyz/' => '',
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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Get input and expected output
    expected = {
      '/' => '',
      '/foo' => '',
      '/foo.html' => '.html',
      '/foo.xyz.html' => '.xyz.html',
      '/foo/' => '',
      '/foo.xyz/' => '',
      '/foo/bar' => '',
      '/foo/bar.html' => '.html',
      '/foo/bar.xyz.html' => '.xyz.html',
      '/foo/bar/' => '',
      '/foo/bar.xyz/' => '',
      '/foo.xyz/bar.xyz/' => '',
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
end
