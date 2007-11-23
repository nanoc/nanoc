require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class SiteTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
    $quiet = false
  end

  def test_in_site_dir
  end

  def test_from_cwd
  end

end
