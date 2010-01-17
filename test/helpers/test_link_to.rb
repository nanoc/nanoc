# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::LinkToTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::LinkTo

  def test_link_to_with_path
    # Check
    assert_equal(
      '<a href="/foo/">Foo</a>',
      link_to('Foo', '/foo/')
    )
  end

  def test_link_to_with_rep
    # Create rep
    rep = mock
    rep.expects(:path).returns('/bar/')

    # Check
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', rep)
    )
  end

  def test_link_to_with_item
    # Create rep
    item = mock
    item.expects(:path).returns('/bar/')

    # Check
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', item)
    )
  end

  def test_link_to_with_attributes
    # Check
    assert_equal(
      '<a title="Dis mai foo!" href="/foo/">Foo</a>',
      link_to('Foo', '/foo/', :title => 'Dis mai foo!')
    )
  end

  def test_link_to_escape
    # Check
    assert_equal(
      '<a title="Foo &amp; Bar" href="/foo&amp;bar/">Foo &amp; Bar</a>',
      link_to('Foo &amp; Bar', '/foo&bar/', :title => 'Foo & Bar')
    )
  end

  def test_link_to_unless_current_current
    # Create item
    @item_rep = mock
    @item_rep.expects(:path).at_least_once.returns('/foo/')

    # Check
    assert_equal(
      '<span class="active" title="You\'re here.">Bar</span>',
      link_to_unless_current('Bar', @item_rep)
    )
  ensure
    @item = nil
  end

  def test_link_to_unless_current_not_current
    # Create item
    @item_rep = mock
    @item_rep.expects(:path).at_least_once.returns('/foo/')

    # Check
    assert_equal(
      '<a href="/abc/xyz/">Bar</a>',
      link_to_unless_current('Bar', '/abc/xyz/')
    )
  end

  def test_relative_path_to_with_self
    # Mock item
    @item_rep = mock
    @item_rep.expects(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      './',
      relative_path_to('/foo/bar/baz/')
    )
  end

  def test_relative_path_to_with_root
    # Mock item
    @item_rep = mock
    @item_rep.expects(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      '../../../',
      relative_path_to('/')
    )
  end

  def test_relative_path_to_file
    # Mock item
    @item_rep = mock
    @item_rep.expects(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      '../../quux',
      relative_path_to('/foo/quux')
    )
  end

  def test_relative_path_to_dir
    # Mock item
    @item_rep = mock
    @item_rep.expects(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      '../../quux/',
      relative_path_to('/foo/quux/')
    )
  end

  def test_relative_path_to_rep
    # Mock self
    @item_rep = mock
    @item_rep.expects(:path).returns('/foo/bar/baz/')

    # Mock other
    other_item_rep = mock
    other_item_rep.expects(:path).returns('/foo/quux/')

    # Test
    assert_equal(
      '../../quux/',
      relative_path_to(other_item_rep)
    )
  end

  def test_relative_path_to_item
    # Mock self
    @item_rep = mock
    @item_rep.expects(:path).returns('/foo/bar/baz/')

    # Mock other
    other_item_rep = mock
    other_item_rep.expects(:path).returns('/foo/quux/')
    other_item = mock
    other_item.expects(:rep).with(:default).returns(other_item_rep)

    # Test
    assert_equal(
      '../../quux/',
      relative_path_to(other_item)
    )
  end

end
