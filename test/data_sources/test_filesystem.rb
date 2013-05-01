# encoding: utf-8

class Nanoc::DataSources::FilesystemTest < Nanoc::TestCase

  def setup
    super
    site = Nanoc::Site.new({})
    @data_source = Nanoc::DataSources::Filesystem.new(site, nil, nil, {})
  end

  def test_all_base_filenames_in
    File.write('index.html',        'x')
    File.write('reviews.html',      'x')
    File.write('reviews.html.yaml', 'x')
    File.write('meta.yaml',         'x')

    expected_filenames = %w( ./index.html ./reviews.html ./meta ).sort
    actual_filenames   = @data_source.send(:all_base_filenames_in, '.')

    assert_equal(expected_filenames, actual_filenames)
  end

  def test_binary_extension?
    assert @data_source.send(:binary_extension?, 'foo')
    refute @data_source.send(:binary_extension?, 'txt')
  end

  def test_content_and_attributes_for_data_with_metadata
    data = "---\nfoo: 123\n---\n\nHello!"

    actual_content, actual_attributes =
      @data_source.send(:content_and_attributes_for_data, data)

    expected_content, expected_attributes =
      "Hello!", { "foo" => 123 }

    assert_equal expected_content, actual_content
    assert_equal expected_attributes, actual_attributes
  end



  # OLD STUFF BELOW THIS POINT
=begin
  def new_data_source(params=nil)
    site = Nanoc::Site.new({})
    Nanoc::DataSources::Filesystem.new(site, nil, nil, params)
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
        { 'num' => 1, :filename => 'foo/bar.html',   :extension => 'html' },
        '/bar/',
        :binary => false, :mtime => File.mtime('foo/bar.html')
      ),
      klass.new(
        'test 2',
        { 'num' => 2, :filename => 'foo/b.c.html',   :extension => 'c.html' },
        '/b/',
        :binary => false, :mtime => File.mtime('foo/b.c.html')
      ),
      klass.new(
        'test 3',
        { 'num' => 3, :filename => 'foo/a/b/c.html', :extension => 'html' },
        '/a/b/c/',
        :binary => false, :mtime => File.mtime('foo/a/b/c.html')
      )
    ]
    actual_out = data_source.send(:load_objects, 'foo', 'The Foo', klass).sort_by { |i| i.stuff[0] }

    # Check
    (0..expected_out.size-1).each do |i|
      assert_equal expected_out[i].stuff[0], actual_out[i].stuff[0], 'content must match'
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2].to_s, 'identifier must match'
      assert_equal expected_out[i].stuff[3][:mtime], actual_out[i].stuff[3][:mtime], 'mtime must match'
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
      actual_output = data_source.send(:identifier_for_filename, input).to_s
      assert_equal(expected_output, actual_output)
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
          data_source.instance_eval { identifier_for_filename(filename) }.to_s
        )
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
          :extension        => nil
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
          :extension        => 'html.erb'
        },
        '/b/',
        :binary => false, :mtime => File.mtime('foo/b.html.erb') > File.mtime('foo/b.yaml') ? File.mtime('foo/b.html.erb') : File.mtime('foo/b.yaml')
      ),
      klass.new(
        'test 3',
        {
          :content_filename => 'foo/car.html',
          :meta_filename    => nil,
          :extension        => 'html'
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
      assert_equal expected_out[i].stuff[2], actual_out[i].stuff[2].to_s, 'identifier must match'
      assert_equal expected_out[i].stuff[3][:mtime], actual_out[i].stuff[3][:mtime], 'mtime must match'

      actual_file   = actual_out[i].stuff[1][:file]
      expected_file = expected_out[i].stuff[1][:file]
      assert(actual_file == expected_file || actual_file.path == expected_file.path, 'file paths must match')

      [ 'num', :content_filename, :meta_filename, :extension ].each do |key|
        assert_equal expected_out[i].stuff[1][key], actual_out[i].stuff[1][key], "attribute key #{key} must match"
      end
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

  def test_setup
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Remove files to make sure they are recreated
    FileUtils.rm_rf('content')
    FileUtils.rm_rf('layouts/default')
    FileUtils.rm_rf('lib')

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:load_objects).with('content', 'item', Nanoc::Item)
    data_source.items
  end

  def test_layouts
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:load_objects).with('layouts', 'layout', Nanoc::Layout)
    data_source.layouts
  end

  def test_create_item
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:create_object).with('content', 'the content', 'the attributes', 'the identifier', {})
    data_source.create_item('the content', 'the attributes', 'the identifier')
  end

  def test_create_layout
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Check
    data_source.expects(:create_object).with('layouts', 'the content', 'the attributes', 'the identifier', {})
    data_source.create_layout('the content', 'the attributes', 'the identifier')
  end

  def test_all_split_files_in_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Write sample files
    %w( foo.html foo.xhtml foo.txt foo.yaml bar.html qux.yaml ).each do |filename|
      File.open(filename, 'w') { |io| io.write('test') }
    end

    # Check
    assert_raises RuntimeError do
      data_source.send(:all_split_files_in, '.')
    end
  end

  def test_basename_of_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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

  def test_ext_of_disallowing_periods_in_identifiers
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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

    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

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
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Parse it
    result = data_source.instance_eval { parse('test.html', 'test.yaml', 'foobar') }
    assert_equal({ "foo" => "bar"}, result[0])
    assert_equal("blah blah",       result[1])
  end

  def test_encoding_default
    File.write('test.txt', 'I ♥ Ruby')

    # Create data sources
    config = {}
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, config)

    # Parse
    data = data_source.send(:read, 'test.txt')
    assert_equal Encoding.find('utf-8'), data.encoding
    assert_equal 'I ♥ Ruby', data
  end

  def test_encoding_custom
    File.write('test.txt', "Hall\xE5!")

    # Create data sources
    config = { encoding: 'ISO-8859-1' }
    data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, config)

    # Parse
    data = data_source.send(:read, 'test.txt')
    assert_equal Encoding.find('utf-8'), data.encoding
    assert_equal 'Hallå!', data
  end
=end

end
