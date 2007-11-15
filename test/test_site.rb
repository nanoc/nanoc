require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class SiteTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp'
    $quiet = false
  end

  def test_create_page
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')

    assert_nothing_raised()   { $nanoc_site = Nanoc::Site.from_cwd }

    assert_nothing_raised()   { $nanoc_site.create_page('test') }
    assert_raise(SystemExit)  { $nanoc_site.create_page('test') }

    assert_nothing_raised()   { $nanoc_site.create_page('foo/bar') }
    assert_raise(SystemExit)  { $nanoc_site.create_page('foo/bar') }

    assert(File.directory?('content/test/'))
    assert(File.file?('content/test/test.txt'))
    assert(File.file?('content/test/meta.yaml'))

    assert(File.directory?('content/foo/bar/'))
    assert(File.file?('content/foo/bar/bar.txt'))
    assert(File.file?('content/foo/bar/meta.yaml'))

    FileUtils.cd('..')
    FileUtils.cd('..')
  end

  def test_create_template
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')
  
    assert_nothing_raised()   { $nanoc_site = Nanoc::Site.from_cwd }
    assert_nothing_raised()   { $nanoc_site.create_template('test') }
    assert_raise(SystemExit)  { $nanoc_site.create_template('test') }

    assert(File.directory?('templates/test/'))
    assert(File.file?('templates/test/test.txt'))
    assert(File.file?('templates/test/meta.yaml'))

    FileUtils.cd('..')
    FileUtils.cd('..')
  end

  #def test_create_page
  #end

  def test_create_page_with_existing_name
  end

  #def test_create_template
  #end

  def test_create_template_with_existing_name
  end

  def test_create_layout
  end

  def test_create_layout_with_existing_name
  end

end
