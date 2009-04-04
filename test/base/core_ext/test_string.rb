require 'test/helper'

class Nanoc::CoreExtStringTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_cleaned_path
    assert_equal('/foo/bar/', '/foo/bar/'.cleaned_path)
    assert_equal('/foo/bar/', '/foo/bar'.cleaned_path)
    assert_equal('/foo/bar/', 'foo/bar/'.cleaned_path)
    assert_equal('/foo/bar/', 'foo/bar'.cleaned_path)
    assert_equal('/foo/bar/', '//foo/bar/'.cleaned_path)
    assert_equal('/foo/bar/', 'foo/bar//'.cleaned_path)
  end

end
