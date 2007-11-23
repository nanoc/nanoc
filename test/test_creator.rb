require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CreatorTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
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
    assert(File.file?('tmp/site/content/content.yaml'))

    assert(File.directory?('tmp/site/layouts/'))
    assert(File.file?('tmp/site/layouts/default.erb'))

    assert(File.directory?('tmp/site/lib/'))
    assert(File.file?('tmp/site/lib/default.rb'))

    assert(File.directory?('tmp/site/output/'))

    assert(File.directory?('tmp/site/templates/'))
    assert(File.directory?('tmp/site/templates/default/'))
    assert(File.file?('tmp/site/templates/default/default.txt'))
    assert(File.file?('tmp/site/templates/default/default.yaml'))

    assert(File.directory?('tmp/site/tasks/'))
    assert(File.file?('tmp/site/tasks/default.rake'))
  end

  def test_create_site_with_existing_name
    FileUtils.cd('tmp')
    assert_nothing_raised()   { $nanoc_creator.create_site('site') }
    assert_raise(SystemExit)  { $nanoc_creator.create_site('site') }
    FileUtils.cd('..')
  end

end
