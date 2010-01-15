# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemCompactTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_identifier_for_filename_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Get input and expected output
    expected = {
      '/foo'            => '/foo/',
      '/foo.html'       => '/foo/',
      '/foo/index.html' => '/foo/',
      '/foo.entry.html' => '/foo.entry/'
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
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Get input and expected output
    expected = {
      '/foo'            => '/foo/',
      '/foo.html'       => '/foo/',
      '/foo/index.html' => '/foo/',
      '/foo.html.erb'   => '/foo/'
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
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Build directory
    FileUtils.mkdir_p('foo')
    File.open('foo/bar.yaml',         'w') { |io| io.write('test') }
    File.open('foo/bar.html',         'w') { |io| io.write('test') }
    File.open('foo/quxbar.yaml',      'w') { |io| io.write('test') }
    File.open('foo/quxbar.html',      'w') { |io| io.write('test') }
    File.open('foo/barqux.yaml',      'w') { |io| io.write('test') }
    File.open('foo/barqux.html',      'w') { |io| io.write('test') }
    File.open('foo/quxbarqux.yaml',   'w') { |io| io.write('test') }
    File.open('foo/quxbarqux.html',   'w') { |io| io.write('test') }
    File.open('foo/qux.bar.yaml',     'w') { |io| io.write('test') }
    File.open('foo/qux.bar.html',     'w') { |io| io.write('test') }
    File.open('foo/bar.qux.yaml',     'w') { |io| io.write('test') }
    File.open('foo/bar.qux.html',     'w') { |io| io.write('test') }
    File.open('foo/qux.bar.qux.yaml', 'w') { |io| io.write('test') }
    File.open('foo/qux.bar.qux.html', 'w') { |io| io.write('test') }

    # Check content filename
    {
      'foo/bar.yaml'         => '/foo/bar/',
      'foo/quxbar.yaml'      => '/foo/quxbar/',
      'foo/barqux.yaml'      => '/foo/barqux/',
      'foo/quxbarqux.yaml'   => '/foo/quxbarqux/',
      'foo/qux.bar.yaml'     => '/foo/qux.bar/',
      'foo/bar.qux.yaml'     => '/foo/bar.qux/',
      'foo/qux.bar.qux.yaml' => '/foo/qux.bar.qux/'
    }.each_pair do |meta_filename, expected_identifier|
      assert_equal(
        expected_identifier,
        data_source.instance_eval { identifier_for_filename(meta_filename) }
      )
    end
  end

  def test_identifier_for_filename_with_subfilename_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo')
    File.open('foo/bar.yaml',         'w') { |io| io.write('test') }
    File.open('foo/bar.html',         'w') { |io| io.write('test') }
    File.open('foo/quxbar.yaml',      'w') { |io| io.write('test') }
    File.open('foo/quxbar.html',      'w') { |io| io.write('test') }
    File.open('foo/barqux.yaml',      'w') { |io| io.write('test') }
    File.open('foo/barqux.html',      'w') { |io| io.write('test') }
    File.open('foo/quxbarqux.yaml',   'w') { |io| io.write('test') }
    File.open('foo/quxbarqux.html',   'w') { |io| io.write('test') }
    File.open('foo/qux.bar.yaml',     'w') { |io| io.write('test') }
    File.open('foo/qux.bar.html',     'w') { |io| io.write('test') }
    File.open('foo/bar.qux.yaml',     'w') { |io| io.write('test') }
    File.open('foo/bar.qux.html',     'w') { |io| io.write('test') }
    File.open('foo/qux.bar.qux.yaml', 'w') { |io| io.write('test') }
    File.open('foo/qux.bar.qux.html', 'w') { |io| io.write('test') }

    # Check content filename
    {
      'foo/bar.yaml'         => '/foo/bar/',
      'foo/quxbar.yaml'      => '/foo/quxbar/',
      'foo/barqux.yaml'      => '/foo/barqux/',
      'foo/quxbarqux.yaml'   => '/foo/quxbarqux/',
      'foo/qux.bar.yaml'     => '/foo/qux/',
      'foo/bar.qux.yaml'     => '/foo/bar/',
      'foo/qux.bar.qux.yaml' => '/foo/qux/'
    }.each_pair do |meta_filename, expected_identifier|
      assert_equal(
        expected_identifier,
        data_source.instance_eval { identifier_for_filename(meta_filename) }
      )
    end
  end

  def test_basename_of_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

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
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

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
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

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
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

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

  def test_all_files_in_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

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
    output_actual = data_source.send :all_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_files_in_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

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
    output_actual = data_source.send :all_files_in, '.'

    # Check
    assert_equal output_expected, output_actual
  end

  def test_all_files_in_with_multiple_content_files
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Write sample files
    %w( foo.html foo.xhtml foo.txt foo.yaml bar.html qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    assert_raises RuntimeError do
      data_source.send :all_files_in, '.'
    end
  end

  def test_load_objects_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

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
    File.open('foo/b.c.html',       'w') { |io| io.write("test 2")        }
    File.open('foo/car.html',       'w') { |io| io.write("test 3")        }
    File.open('foo/ugly.yaml~',     'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html~',     'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write("blah")          }

    # Get expected output
    expected_out = [
      klass.new(
        '',
        {
          'num'             => 1,
          :content_filename => nil,
          :meta_filename    => 'foo/a/b/c.yaml',
          :extension        => nil,
          :file             => nil
        },
        '/a/b/c/',
        File.mtime('foo/a/b/c.yaml')
      ),
      klass.new(
        'test 2',
        {
          'num'             => 2,
          :content_filename => 'foo/b.c.html',
          :meta_filename    => 'foo/b.c.yaml',
          :extension        => 'html',
          :file             => File.open('foo/b.c.html')
        },
        '/b.c/',
        File.mtime('foo/b.c.html') > File.mtime('foo/b.c.yaml') ? File.mtime('foo/b.c.html') : File.mtime('foo/b.c.yaml')
      ),
      klass.new(
        'test 3',
        {
          :content_filename => 'foo/car.html',
          :meta_filename    => nil,
          :extension        => 'html',
          :file             => File.open('foo/car.html')
        },
        '/car/',
        File.mtime('foo/car.html')
      )
    ]

    # Get actual output ordered by identifier
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[2] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      assert_equal expected_out[i].stuff[3], actual_out[i].stuff[3], 'mtime must match'

      actual_file   = actual_out[i].stuff[1][:file]
      expected_file = expected_out[i].stuff[1][:file]
      assert(actual_file == expected_file || actual_file.path == expected_file.path, 'file paths must match')

      [ 'num', :content_filename, :meta_filename, :extension ].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_load_objects_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

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
    File.open('foo/b.html.erb',     'w') { |io| io.write("test 2")        }
    File.open('foo/car.html',       'w') { |io| io.write("test 3")        }
    File.open('foo/ugly.yaml~',     'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html~',     'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html.orig', 'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html.rej',  'w') { |io| io.write("blah")          }
    File.open('foo/ugly.html.bak',  'w') { |io| io.write("blah")          }

    # Get expected output
    expected_out = [
      klass.new(
        '',
        {
          'num'             => 1,
          :content_filename => nil,
          :meta_filename    => 'foo/a/b/c.yaml',
          :extension        => nil,
          :file             => nil
        },
        '/a/b/c/',
        File.mtime('foo/a/b/c.yaml')
      ),
      klass.new(
        'test 2',
        {
          'num'             => 2,
          :content_filename => 'foo/b.html.erb',
          :meta_filename    => 'foo/b.yaml',
          :extension        => 'html.erb',
          :file             => File.open('foo/b.html.erb')
        },
        '/b/',
        File.mtime('foo/b.html.erb') > File.mtime('foo/b.yaml') ? File.mtime('foo/b.html.erb') : File.mtime('foo/b.yaml')
      ),
      klass.new(
        'test 3',
        {
          :content_filename => 'foo/car.html',
          :meta_filename    => nil,
          :extension        => 'html',
          :file             => File.open('foo/car.html')
        },
        '/car/',
        File.mtime('foo/car.html')
      )
    ]

    # Get actual output ordered by identifier
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[2] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      assert_equal expected_out[i].stuff[3], actual_out[i].stuff[3], 'mtime must match'

      actual_file   = actual_out[i].stuff[1][:file]
      expected_file = expected_out[i].stuff[1][:file]
      assert(actual_file == expected_file || actual_file.path == expected_file.path, 'file paths must match')

      [ 'num', :content_filename, :meta_filename, :extension ].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_create_object_allowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Create object without period
    data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/asdf/')
    assert File.file?('foo/asdf.yaml')
    assert File.file?('foo/asdf.html')
    assert_equal('some content', File.read('foo/asdf.html'))
    assert_equal({ 'some' => 'attributes' }, YAML.load_file('foo/asdf.yaml'))

    # Create object with period
    data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/as.df/')
    assert File.file?('foo/as.df.yaml')
    assert File.file?('foo/as.df.html')
    assert_equal('some content', File.read('foo/as.df.html'))
    assert_equal({ 'some' => 'attributes' }, YAML.load_file('foo/as.df.yaml'))
  end

  def test_create_object_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Create object without period
    data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/asdf/')
    assert File.file?('foo/asdf.yaml')
    assert File.file?('foo/asdf.html')
    assert_equal('some content', File.read('foo/asdf.html'))
    assert_equal({ 'some' => 'attributes' }, YAML.load_file('foo/asdf.yaml'))

    # Create object with period
    assert_raises(RuntimeError) do
      data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/as.df/')
    end
  end

  def test_compile_huge_site
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCompact.new(nil, nil, nil, nil)

    # Create a lot of items
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    count.times do |i|
      FileUtils.mkdir_p("content/#{i}")
      File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is item #{i}." }
      File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Item #{i}"   }
    end

    # Read all items
    data_source.items
  end

end
