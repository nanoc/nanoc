require 'test/helper'

class Nanoc3::DataSources::FilesystemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  # Test preparation

  def test_setup
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Remove files to make sure they are recreated
    FileUtils.rm_rf('assets')
    FileUtils.rm_rf('content')
    FileUtils.rm_rf('layouts/default')
    FileUtils.rm_rf('lib/default.rb')

    # Mock VCS
    vcs = mock
    vcs.expects(:add).times(4) # One time for each directory
    data_source.vcs = vcs

    # Recreate files
    data_source.setup

    # Ensure essential files have been recreated
    assert(File.directory?('assets/'))
    assert(File.directory?('content/'))
    assert(File.directory?('layouts/'))
    assert(File.directory?('lib/'))

    # Ensure no non-essential files have been recreated
    assert(!File.file?('content/content.html'))
    assert(!File.file?('content/content.yaml'))
    assert(!File.directory?('layouts/default/'))
    assert(!File.file?('lib/default.rb'))
  end

  # Test loading data

  def test_pages
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Create foo page
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.yaml', 'w') do |io|
      io.write("title: Foo\n")
    end
    File.open('content/foo/foo.html', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Create bar page
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar/bar.yaml', 'w') do |io|
      io.write("title: Bar\n")
    end
    File.open('content/bar/bar.html', 'w') do |io|
      io.write("Lorem ipsum dolor sit amet...")
    end

    # Load pages
    pages = data_source.pages

    # Check pages
    assert_equal(2, pages.size)
    assert(pages.any? { |a| a.attribute_named(:title) == 'Foo' })
    assert(pages.any? { |a| a.attribute_named(:title) == 'Bar' })
  end

  def test_assets
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Create asset with extension
    FileUtils.mkdir_p('assets/foo')
    File.open('assets/foo/foo.yaml', 'w') do |io|
      io.write("filters: []\n")
      io.write("extension: newfooext\n")
    end
    File.open('assets/foo/foo.fooext', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Create asset without extension
    FileUtils.mkdir_p('assets/bar')
    File.open('assets/bar/bar.yaml', 'w') do |io|
      io.write("filters: []\n")
    end
    File.open('assets/bar/bar.barext', 'w') do |io|
      io.write("Lorem ipsum dolor sit amet...")
    end

    # Load assets
    assets = data_source.assets

    # Check assets
    assert_equal(2, assets.size)
    assert(assets.any? { |a| a.attribute_named(:extension) == 'newfooext' })
    assert(assets.any? { |a| a.attribute_named(:extension) == 'barext' })
  end

  def test_layouts
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Create layout
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write("filter: erb\n")
    end
    File.open('layouts/foo/foo.rhtml', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Load layouts
    layouts = data_source.layouts

    # Check layouts
    assert_equal(1,     layouts.size)
    assert_equal('erb', layouts[0].attribute_named(:filter))
  end

  def test_code
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Create code
    FileUtils.mkdir_p('lib')
    File.open('lib/foo.rb', 'w') do |io|
      io.write("# This is a bit of code right here...\n")
    end

    # Load code
    code = data_source.code

    # Check code
    assert_equal(
      [ { :code => "# This is a bit of code right here...\n", :filename => 'lib/foo.rb' } ],
      code.snippets
    )
  end

  # Test creating data

  def test_create_page_at_root
    # Create page
    data_source = Nanoc3::DataSources::Filesystem.new(nil)
    data_source.create_page('content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('content')
    assert File.file?('content/content.html')
    assert File.file?('content/content.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/content.html')
    assert_match 'foo: bar',     File.read('content/content.yaml')
  end

  def test_create_page_not_at_root
    # Create page
    data_source = Nanoc3::DataSources::Filesystem.new(nil)
    data_source.create_page('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('content/moo')
    assert File.file?('content/moo/moo.html')
    assert File.file?('content/moo/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/moo/moo.html')
    assert_match 'foo: bar',     File.read('content/moo/moo.yaml')
  end

  def test_create_layout
    # Create layout
    data_source = Nanoc3::DataSources::Filesystem.new(nil)
    data_source.create_layout('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('layouts/moo')
    assert File.file?('layouts/moo/moo.html')
    assert File.file?('layouts/moo/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('layouts/moo/moo.html')
    assert_match 'foo: bar',     File.read('layouts/moo/moo.yaml')
  end

  # Test private methods

  def test_meta_filenames
    # TODO implement
  end

  def test_content_filename_for_dir_with_one_content_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_two_content_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.xhtml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_raises(RuntimeError) do
      assert_equal(
        'foo/bar/baz/baz.html',
        data_source.instance_eval do
          content_filename_for_dir('foo/bar/baz')
        end
      )
    end
  end

  def test_content_filename_for_dir_with_one_content_and_one_meta_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_and_many_meta_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/foo.yaml', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/zzz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_file_and_rejected_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html~', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html.orig', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html.rej', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html.bak', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_index_content_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/index.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/index.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  # Miscellaneous

  def test_meta_filenames_error
    # TODO implement
  end

  def test_content_filename_for_dir_error
    # TODO implement
  end

  def test_content_filename_for_dir_index_error
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('foo/index')
    File.open('foo/index/index.html', 'w') { |io| io.write('test') }

    # Check
    assert_equal(
      'foo/index/index.html',
      data_source.instance_eval { content_filename_for_dir('foo/index') }
    )
  end

  def test_compile_huge_site
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    # Create a lot of pages
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    count.times do |i|
      FileUtils.mkdir_p("content/#{i}")
      File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is page #{i}." }
      File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Page #{i}"   }
    end

    # Read all pages
    data_source.pages
  end

end
