require 'test/helper'

class Nanoc::Filters::RelativizePathsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter_with_double_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = MiniTest::Mock.new
      @item.expect(:path, '/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a>]
    expected_content = %[<a href="../..">foo</a>]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_with_single_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = MiniTest::Mock.new
      @item.expect(:path, '/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href='/foo'>foo</a>]
    expected_content = %[<a href='../..'>foo</a>]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_multiple
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = MiniTest::Mock.new
      @item.expect(:path, '/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a> <a href="/bar">bar</a>]
    expected_content = %[<a href="../..">foo</a> <a href="../../../bar">bar</a>]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

end
