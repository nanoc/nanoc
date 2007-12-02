require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class SiteTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_from_cwd_right
    # Test presence of site
    in_dir %w{ tmp } do
      assert(Nanoc::Site.from_cwd.nil?)
    end
  end

  def test_from_cwd_wrong
    # Create site
    FileUtils.cd('tmp')
    $nanoc_creator.create_site('site')
    FileUtils.cd('..')

    # Test presence of site
    in_dir %w{ tmp site } do
      assert(!Nanoc::Site.from_cwd.nil?)
    end
  end

end
