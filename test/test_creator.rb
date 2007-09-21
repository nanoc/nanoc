require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CreatorTest < Test::Unit::TestCase
  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp'
    $quiet = false
  end

  def test_create_site
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('..')

    assert(File.directory?('tmp/site/'))

    assert(File.file?('tmp/site/config.yaml'))
    assert(File.file?('tmp/site/meta.yaml'))
    assert(File.file?('tmp/site/Rakefile'))

    assert(File.directory?('tmp/site/content/'))
    assert(File.file?('tmp/site/content/content.txt'))
    assert(File.file?('tmp/site/content/meta.yaml'))

    assert(File.directory?('tmp/site/layouts/'))
    assert(File.file?('tmp/site/layouts/default.erb'))

    assert(File.directory?('tmp/site/lib/'))
    assert(File.file?('tmp/site/lib/default.rb'))

    assert(File.directory?('tmp/site/output/'))

    assert(File.directory?('tmp/site/templates/'))
    assert(File.directory?('tmp/site/templates/default/'))
    assert(File.file?('tmp/site/templates/default/default.txt'))
    assert(File.file?('tmp/site/templates/default/meta.yaml'))

    assert(File.directory?('tmp/site/tasks/'))
    assert(File.file?('tmp/site/tasks/default.rake'))
  end

  def test_create_site_with_existing_name
    FileUtils.cd('tmp')
    assert_nothing_raised()   { $nanoc_creator.create_site('site') }
    assert_raise(SystemExit)  { $nanoc_creator.create_site('site') }
    FileUtils.cd('..')
  end

  def test_create_page
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')
    $nanoc_creator.create_page('moo')
    FileUtils.cd('..')
    FileUtils.cd('..')

    assert(File.directory?('tmp/site/content/moo/'))
    assert(File.file?('tmp/site/content/moo/moo.txt'))
    assert(File.file?('tmp/site/content/moo/meta.yaml'))
  end

  def test_create_page_with_existing_name
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')

    assert_nothing_raised()   { $nanoc_creator.create_page('test') }
    assert_raise(SystemExit)  { $nanoc_creator.create_page('test') }

    assert_nothing_raised()   { $nanoc_creator.create_page('foo/bar') }
    assert_raise(SystemExit)  { $nanoc_creator.create_page('foo/bar') }

    FileUtils.cd('..')
    FileUtils.cd('..')
  end

  def test_create_template
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')
    $nanoc_creator.create_template('moo')
    FileUtils.cd('..')
    FileUtils.cd('..')

    assert(File.directory?('tmp/site/templates/moo/'))
    assert(File.file?('tmp/site/templates/moo/moo.txt'))
    assert(File.file?('tmp/site/templates/moo/meta.yaml'))
  end

  def test_create_template_with_existing_name
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('site')

    assert_nothing_raised()   { $nanoc_creator.create_template('test') }
    assert_raise(SystemExit)  { $nanoc_creator.create_template('test') }

    FileUtils.cd('..')
    FileUtils.cd('..')
  end
end
