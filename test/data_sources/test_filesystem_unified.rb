# encoding: utf-8

class Nanoc::DataSources::FilesystemUnifiedTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def new_data_source(params=nil)
    # Mock site
    site = Nanoc::Site.new({})

    # Create data source
    data_source = Nanoc::DataSources::FilesystemUnified.new(site, nil, nil, params)

    # Done
    data_source
  end

  def test_create_object_not_at_root
    # Create item
    data_source = new_data_source
    data_source.send(:create_object, 'foobar', 'content here', { :foo => 'bar' }, '/asdf/')

    # Check file existance
    assert File.directory?('foobar')
    assert !File.directory?('foobar/content')
    assert !File.directory?('foobar/asdf')
    assert File.file?('foobar/asdf.html')

    # Check file content
    expected = /^--- ?\nfoo: bar\n---\n\ncontent here$/
    assert_match expected, File.read('foobar/asdf.html')
  end

  def test_create_object_at_root
    # Create item
    data_source = new_data_source
    data_source.send(:create_object, 'foobar', 'content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('foobar')
    assert !File.directory?('foobar/index')
    assert !File.directory?('foobar/foobar')
    assert File.file?('foobar/index.html')

    # Check file content
    expected = /^--- ?\nfoo: bar\n---\n\ncontent here$/
    assert_match expected, File.read('foobar/index.html')
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
        { 'num' => 1, :filename => 'foo/bar.html',   :extension => 'html', :file => File.open('foo/bar.html') },
        '/bar/',
        :binary => false, :mtime => File.mtime('foo/bar.html')
      ),
      klass.new(
        'test 2',
        { 'num' => 2, :filename => 'foo/b.c.html',   :extension => 'c.html', :file => File.open('foo/b.c.html') },
        '/b/',
        :binary => false, :mtime => File.mtime('foo/b.c.html')
      ),
      klass.new(
        'test 3',
        { 'num' => 3, :filename => 'foo/a/b/c.html', :extension => 'html', :file => File.open('foo/a/b/c.html') },
        '/a/b/c/',
        :binary => false, :mtime => File.mtime('foo/a/b/c.html')
      )
    ]
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[0] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      assert_equal expected_out[i].stuff[3][:mtime], actual_out[i].stuff[3][:mtime], 'mtime must match'
      assert_equal expected_out[i].stuff[1][:file].path, actual_out[i].stuff[1][:file].path, 'file paths must match'
      expected_out[i].stuff[1][:file].close;
      actual_out[i].stuff[1][:file].close
      [ 'num', :filename, :extension ].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_load_binary_objects
    # Create data source
    data_source = new_data_source

    # Create sample files
    FileUtils.mkdir_p('foo')
    File.open('foo/stuff.dat', 'w') { |io| io.write("random binary data") }

    # Load
    items = data_source.send(:load_objects, 'foo', 'item', Nanoc::Item)

    # Check
    assert_equal 1, items.size
    assert items[0].binary?
    assert_equal 'foo/stuff.dat', items[0].raw_filename
    assert_nil items[0].raw_content
  end

  def test_load_binary_layouts
    # Create data source
    data_source = new_data_source

    # Create sample files
    FileUtils.mkdir_p('foo')
    File.open('foo/stuff.dat', 'w') { |io| io.write("random binary data") }

    # Load
    items = data_source.send(:load_objects, 'foo', 'item', Nanoc::Layout)

    # Check
    assert_equal 1, items.size
    assert_equal 'random binary data', items[0].raw_content
  end

  def test_identifier_for_filename_allowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source(:allow_periods_in_identifiers => true)

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
    data_source = new_data_source

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
    expectations = {
      'foo/bar.yaml'         => '/foo/bar/',
      'foo/quxbar.yaml'      => '/foo/quxbar/',
      'foo/barqux.yaml'      => '/foo/barqux/',
      'foo/quxbarqux.yaml'   => '/foo/quxbarqux/',
      'foo/qux.bar.yaml'     => '/foo/qux.bar/',
      'foo/bar.qux.yaml'     => '/foo/bar.qux/',
      'foo/qux.bar.qux.yaml' => '/foo/qux.bar.qux/',
      'foo/index.yaml'       => '/foo/',
      'index.yaml'           => '/',
      'foo/blah_index.yaml'  => '/foo/blah_index/'
    }

    data_source = new_data_source(:allow_periods_in_identifiers => true)
    expectations.each_pair do |meta_filename, expected_identifier|
      content_filename = meta_filename.sub(/yaml$/, 'html')
      [ meta_filename, content_filename ].each do |filename|
        assert_equal(
          expected_identifier,
          data_source.instance_eval { identifier_for_filename(filename) }
        )
      end
    end
  end

  def test_identifier_for_filename_with_subfilename_disallowing_periods_in_identifiers
    expectations = {
      'foo/bar.yaml'         => '/foo/bar/',
      'foo/quxbar.yaml'      => '/foo/quxbar/',
      'foo/barqux.yaml'      => '/foo/barqux/',
      'foo/quxbarqux.yaml'   => '/foo/quxbarqux/',
      'foo/qux.bar.yaml'     => '/foo/qux/',
      'foo/bar.qux.yaml'     => '/foo/bar/',
      'foo/qux.bar.qux.yaml' => '/foo/qux/',
      'foo/index.yaml'       => '/foo/',
      'index.yaml'           => '/',
      'foo/blah_index.yaml'  => '/foo/blah_index/'
    }

    data_source = new_data_source
    expectations.each_pair do |meta_filename, expected_identifier|
      content_filename = meta_filename.sub(/yaml$/, 'html')
      [ meta_filename, content_filename ].each do |filename|
        assert_equal(
          expected_identifier,
          data_source.instance_eval { identifier_for_filename(filename) }
        )
      end
    end
  end

  def test_load_objects_allowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source(:allow_periods_in_identifiers => true)

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
        :binary => false, :mtime => File.mtime('foo/a/b/c.yaml')
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
        :binary => false, :mtime => File.mtime('foo/b.c.html') > File.mtime('foo/b.c.yaml') ? File.mtime('foo/b.c.html') : File.mtime('foo/b.c.yaml')
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
        :binary => false, :mtime => File.mtime('foo/car.html')
      )
    ]

    # Get actual output ordered by identifier
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[2] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      assert_equal expected_out[i].stuff[3][:mtime], actual_out[i].stuff[3][:mtime], 'mtime must match'

      actual_file   = actual_out[i].stuff[1][:file]
      expected_file = expected_out[i].stuff[1][:file]
      assert(actual_file == expected_file || actual_file.path == expected_file.path, 'file paths must match')
      actual_file.close unless actual_file.nil?
      expected_file.close unless expected_file.nil?

      [ 'num', :content_filename, :meta_filename, :extension ].each do |key|
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
        :binary => false, :mtime => File.mtime('foo/a/b/c.yaml')
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
        :binary => false, :mtime => File.mtime('foo/b.html.erb') > File.mtime('foo/b.yaml') ? File.mtime('foo/b.html.erb') : File.mtime('foo/b.yaml')
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
        :binary => false, :mtime => File.mtime('foo/car.html')
      )
    ]

    # Get actual output ordered by identifier
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[2] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2], 'identifier must match'
      assert_equal expected_out[i].stuff[3][:mtime], actual_out[i].stuff[3][:mtime], 'mtime must match'

      actual_file   = actual_out[i].stuff[1][:file]
      expected_file = expected_out[i].stuff[1][:file]
      assert(actual_file == expected_file || actual_file.path == expected_file.path, 'file paths must match')
      actual_file.close unless actual_file.nil?
      expected_file.close unless expected_file.nil?

      [ 'num', :content_filename, :meta_filename, :extension ].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
    end
  end

  def test_create_object_allowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source(:allow_periods_in_identifiers => true)

    # Create object without period
    data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/asdf/')
    assert File.file?('foo/asdf.html')
    data = data_source.send(:parse, 'foo/asdf.html', nil, 'moo')
    assert_equal({ 'some' => 'attributes' }, data[0])
    assert_equal('some content',             data[1])

    # Create object with period
    data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/as.df/')
    assert File.file?('foo/as.df.html')
    data = data_source.send(:parse, 'foo/as.df.html', nil, 'moo')
    assert_equal({ 'some' => 'attributes' }, data[0])
    assert_equal('some content',             data[1])
  end

  def test_create_object_disallowing_periods_in_identifiers
    # Create data source
    data_source = new_data_source

    # Create object without period
    data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/asdf/')
    assert File.file?('foo/asdf.html')
    data = data_source.send(:parse, 'foo/asdf.html', nil, 'moo')
    assert_equal({ 'some' => 'attributes' }, data[0])
    assert_equal('some content',             data[1])

    # Create object with period
    assert_raises(RuntimeError) do
      data_source.send(:create_object, 'foo', 'some content', { :some => 'attributes' }, '/as.df/')
    end
  end

  def test_filename_for
    data_source = new_data_source

    assert_equal '/foo.bar',     data_source.send(:filename_for, '/foo', 'bar')
    assert_equal '/foo.bar.baz', data_source.send(:filename_for, '/foo', 'bar.baz')
    assert_equal '/foo',         data_source.send(:filename_for, '/foo', '')
    assert_equal nil,            data_source.send(:filename_for, '/foo', nil)
  end

  def test_compile_huge_site
    if_implemented do
      # Create data source
      data_source = new_data_source

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

  def test_compile_iso_8859_1_site
    # Check encoding
    if !''.respond_to?(:encode)
      skip "Test only works on 1.9.x"
      return
    end

    # Create data source
    data_source = new_data_source

    # Create item
    data_source.create_item("Hëllö", {}, '/foo/')

    # Parse
    begin
      original_default_external_encoding = Encoding.default_external
      Encoding.default_external = 'ISO-8859-1'

      items = data_source.items

      assert_equal 1, items.size
      assert_equal Encoding.find("UTF-8"), items[0].raw_content.encoding
    ensure
      Encoding.default_external = original_default_external_encoding
    end
  end

  def test_compile_iso_8859_1_site_with_explicit_encoding
    # Check encoding
    if !''.respond_to?(:encode)
      skip "Test only works on 1.9.x"
      return
    end

    # Create data source
    data_source = new_data_source({})
    data_source.config[:encoding] = 'ISO-8859-1'

    # Create item
    begin
      original_default_external_encoding = Encoding.default_external
      Encoding.default_external = 'ISO-8859-1'

      data_source.create_item("Hëllö", {}, '/foo/')
    ensure
      Encoding.default_external = original_default_external_encoding
    end

    # Parse
    items = data_source.items
    assert_equal 1, items.size
    assert_equal Encoding.find("UTF-8"), items[0].raw_content.encoding
  end

end
