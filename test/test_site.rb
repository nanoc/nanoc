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
    in_dir %w{ tmp } do
      Nanoc::Site.create('site')
    end

    # Test presence of site
    in_dir %w{ tmp site } do
      assert(!Nanoc::Site.from_cwd.nil?)
    end
  end

end
