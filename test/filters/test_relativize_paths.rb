require 'test/helper'

class Nanoc::Filters::RelativizePathsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter_html_with_double_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a>]
    expected_content = %[<a href="../..">foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_single_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href='/foo'>foo</a>]
    expected_content = %[<a href='../..'>foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_without_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href=/foo>foo</a>]
    expected_content = %[<a href=../..>foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_multiple
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a> <a href="/bar">bar</a>]
    expected_content = %[<a href="../..">foo</a> <a href="../../../bar">bar</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_implicit
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a>]
    expected_content = %[<a href="../..">foo</a>]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_with_double_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[background: url("/foo/bar/background.png");]
    expected_content = %[background: url("../background.png");]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_with_single_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[background: url('/foo/bar/background.png');]
    expected_content = %[background: url('../background.png');]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_without_quotes
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/background.png);]
    expected_content = %[background: url(../background.png);]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_multiple
    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item = mock
      @item.expects(:path).returns('/foo/bar/baz/')
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/a.png) url(/foo/bar/b.png);]
    expected_content = %[background: url(../a.png) url(../b.png);]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

end
