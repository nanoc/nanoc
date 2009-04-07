require 'test/helper'

class Nanoc::Filters::RelativizePathsInCSSInCSSTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter_with_double_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePathsInCSS.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @page = Object.new
      def @page.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url("/foo/bar/background.png");]
    expected_content = %[background: url("../background.png");]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_with_single_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePathsInCSS.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @page = Object.new
      def @page.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url('/foo/bar/background.png');]
    expected_content = %[background: url('../background.png');]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_without_quotes
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePathsInCSS.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @page = Object.new
      def @page.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/background.png);]
    expected_content = %[background: url(../background.png);]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_multiple
    # Mock page and site
    page = mock
    site = mock
    page.expects(:site).returns(site)
    obj_rep = mock
    obj_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    obj_rep.expects(:page).returns(page)

    # Create filter with mock item
    filter = Nanoc::Filters::RelativizePathsInCSS.new(obj_rep)

    # Mock item
    filter.instance_eval do
      @page = Object.new
      def @page.path ; '/foo/bar/baz/' ; end
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/a.png) url(/foo/bar/b.png);]
    expected_content = %[background: url(../a.png) url(../b.png);]

    # Test
    actual_content = filter.run(raw_content)
    assert_equal(expected_content, actual_content)
  end

end
