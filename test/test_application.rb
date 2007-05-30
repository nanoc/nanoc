require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class ApplicationTest < Test::Unit::TestCase
  def setup
    $quiet = true
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp'
    $quiet = false
  end

  def test_in_site?
    in_dir %w{ tmp } do
      assert !Nanoc::Application.in_site?
    end

    with_fixture 'empty_site' do
      assert Nanoc::Application.in_site?
    end
  end

  def test_ensure_in_site
    in_dir %w{ tmp } do
      assert_raise SystemExit do
        Nanoc::Application.ensure_in_site
      end
    end

    with_fixture 'empty_site' do
      assert_nothing_raised do
        Nanoc::Application.ensure_in_site
      end
    end
  end
end
