require 'test/helper'

class Nanoc::Filters::RelativizePathsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter_html_with_double_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a>]
    expected_content = %[<a href="../..">foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_with_single_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[<a href='/foo'>foo</a>]
    expected_content = %[<a href='../..'>foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_without_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[<a href=/foo>foo</a>]
    expected_content = %[<a href=../..>foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_multiple
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a> <a href="/bar">bar</a>]
    expected_content = %[<a href="../..">foo</a> <a href="../../../bar">bar</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_implicit
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a>]
    expected_content = %[<a href="../..">foo</a>]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_with_double_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url("/foo/bar/background.png");]
    expected_content = %[background: url("../background.png");]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_with_single_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url('/foo/bar/background.png');]
    expected_content = %[background: url('../background.png');]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_without_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/background.png);]
    expected_content = %[background: url(../background.png);]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_multiple
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePaths.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @item = Object.new
      def @item.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/a.png) url(/foo/bar/b.png);]
    expected_content = %[background: url(../a.png) url(../b.png);]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

end
