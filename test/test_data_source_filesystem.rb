require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class FilesystemDataSourceTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f if File.exist?(f)}
    $quiet = false
  end

  # Test preparation

  def test_up
  end

  def test_down
  end

  def test_setup
  end

  # Test loading data

  def test_pages
  end

  def test_page_defaults
  end

  def test_templates
  end

  def test_layouts
  end

  # Test creating data

  def test_create_page
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')

    site = Nanoc::Site.from_cwd

    assert_nothing_raised()   { site.create_page('test') }
    assert_raise(SystemExit)  { site.create_page('test') }

    assert_nothing_raised()   { site.create_page('foo/bar') }
    assert_raise(SystemExit)  { site.create_page('foo/bar') }

    assert(File.directory?('content/test/'))
    assert(File.file?('content/test/test.txt'))
    assert(File.file?('content/test/test.yaml'))

    assert(File.directory?('content/foo/bar/'))
    assert(File.file?('content/foo/bar/bar.txt'))
    assert(File.file?('content/foo/bar/bar.yaml'))
  ensure
    FileUtils.cd('..')
    FileUtils.cd('..')
  end

  def test_create_template
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')
  
    site = Nanoc::Site.from_cwd

    assert_nothing_raised()   { site.create_template('test') }
    assert_raise(SystemExit)  { site.create_template('test') }

    assert(File.directory?('templates/test/'))
    assert(File.file?('templates/test/test.txt'))
    assert(File.file?('templates/test/test.yaml'))
  ensure
    FileUtils.cd('..')
    FileUtils.cd('..')
  end

  def test_create_layout
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')
  
    site = Nanoc::Site.from_cwd

    assert_nothing_raised()   { site.create_layout('test') }
    assert_raise(SystemExit)  { site.create_layout('test') }

    assert(File.file?('layouts/test.erb'))
  ensure
    FileUtils.cd('..')
    FileUtils.cd('..')
  end

  # Miscellaneous

  def test_compile_site_with_file_object
    with_site_fixture 'site_with_file_object' do |site|
      assert_nothing_raised() { site.compile }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert(File.read('output/index.html').include?("This page was last modified at #{File.new('content/content.erb').mtime}."))
    end
  end

end
