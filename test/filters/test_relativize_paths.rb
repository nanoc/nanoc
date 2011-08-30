# encoding: utf-8

class Nanoc3::Filters::RelativizePathsTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter_html_with_double_quotes
    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
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
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
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
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
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
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
    end

    # Set content
    raw_content      = %[<a href="/foo">foo</a> <a href="/bar">bar</a>]
    expected_content = %[<a href="../..">foo</a> <a href="../../../bar">bar</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_outside_tag
    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
    end

    # Set content
    raw_content      = %[stuff href="/foo" more stuff]
    expected_content = %[stuff href="/foo" more stuff]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_root
    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/woof/meow/'
    end

    # Set content
    raw_content      = %[<a href="/">foo</a>]
    expected_content = %[<a href="../../">foo</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_html_network_path
    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/woof/meow/'
    end

    # Set content
    raw_content      = %[<a href="//example.com/">example.com</a>]
    expected_content = %[<a href="//example.com/">example.com</a>]

    # Test
    actual_content = filter.run(raw_content, :type => :html)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_implicit
    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Test
    assert_raises(RuntimeError) do
      filter.run("moo")
    end
  end

  def test_filter_css_with_double_quotes
    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
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
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
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
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
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
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/foo/bar/baz/'
    end

    # Set content
    raw_content      = %[background: url(/foo/bar/a.png) url(/foo/bar/b.png);]
    expected_content = %[background: url(../a.png) url(../b.png);]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

  def test_filter_css_root
    # It is probably a bit weird to have “url(/)” in CSS, but I’ve made a
    # test case for this situation anyway. Can’t hurt…

    # Create filter with mock item
    filter = Nanoc3::Filters::RelativizePaths.new

    # Mock item
    filter.instance_eval do
      @item_rep = Nanoc3::ItemRep.new(
        Nanoc3::Item.new(
          'content',
          {},
          '/foo/bar/baz/'),
        :blah)
      @item_rep.path = '/woof/meow/'
    end

    # Set content
    raw_content      = %[background: url(/);]
    expected_content = %[background: url(../../);]

    # Test
    actual_content = filter.run(raw_content, :type => :css)
    assert_equal(expected_content, actual_content)
  end

end
