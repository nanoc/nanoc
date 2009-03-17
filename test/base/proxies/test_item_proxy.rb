require 'test/helper'

class Nanoc3::ItemProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get_with_mtime
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:mtime, Time.parse('2008-05-19'))

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal(Time.parse('2008-05-19'), item_proxy.mtime)

    # Verify mocks
    item.verify
  end

  def test_get_with_parent
    # Mock parent
    parent_proxy = MiniTest::Mock.new
    parent = MiniTest::Mock.new
    parent.expect(:to_proxy, parent_proxy)

    # Mock item
    item = MiniTest::Mock.new
    item.expect(:parent, parent)

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal(parent_proxy, item_proxy.parent)

    # Verify mocks
    item.verify
  end

  def test_get_with_parent_nil
    # Mock item
    item = MiniTest::Mock.new
    item.expect(:parent, nil)

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal(nil, item_proxy.parent)

    # Verify mocks
    item.verify
  end

  def test_get_with_children
    # Mock children
    child_proxy = MiniTest::Mock.new
    child = MiniTest::Mock.new
    child.expect(:to_proxy, child_proxy)

    # Mock item
    item = MiniTest::Mock.new
    item.expect(:children, [ child ])

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal([ child_proxy ], item_proxy.children)

    # Verify mocks
    item.verify
  end

  def test_get_with_content
    # Mock item
    item = MiniTest::Mock.new

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)
    def item_proxy.content ; 'some content and stuff' ; end

    # Test
    assert_equal('some content and stuff', item_proxy[:content])

    # Verify mocks
    item.verify
  end

  def test_get_with_path
    # Mock item and reps
    item_reps = [ mock, mock ]
    item_reps[0].expects(:path).returns('/foo/bar/baz/')
    item_reps[0].expects(:name).returns(:default)
    item_reps[1].stubs(:path).returns('/blah/lorem/ipsum/')
    item_reps[1].stubs(:name).returns(:lorem)
    item = mock
    item.expects(:reps).returns(item_reps)

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)
    def item_proxy.reps ; [ item_rep ] ; end

    # Test
    assert_equal('/foo/bar/baz/', item_proxy.path)
  end

  def test_content_with_default_snapshot
    # Mock item and reps
    item_reps = [ mock, mock ]
    item_reps[0].expects(:content_at_snapshot).with(:pre).returns('blah blah lorem ipsum')
    item_reps[0].expects(:name).returns(:default)
    item_reps[1].stubs(:content_at_snapshot).returns('foo bar baz qux etc')
    item_reps[1].stubs(:name).returns(:lorem)
    item = mock
    item.expects(:reps).returns(item_reps)

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal('blah blah lorem ipsum', item_proxy.content)
  end

  def test_content_with_custom_snapshot
    # Mock item and reps
    item_reps = [ mock, mock ]
    item_reps[0].expects(:content_at_snapshot).with(:zomg).returns('blah blah lorem ipsum')
    item_reps[0].expects(:name).returns(:default)
    item_reps[1].stubs(:content_at_snapshot).returns('foo bar baz qux etc')
    item_reps[1].stubs(:name).returns(:lorem)
    item = mock
    item.expects(:reps).returns(item_reps)

    # Create proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal('blah blah lorem ipsum', item_proxy.content(:zomg))
  end

  def test_get
    # Get item rep
    item_rep = mock
    item_rep.expects(:name).returns(:default)
    item_rep.expects(:path).returns('item rep web path')

    # Get item
    item = mock
    item.expects(:reps).returns([ item_rep ])
    item.expects(:mtime).returns(Time.parse('2008-05-19'))
    item.expects(:attribute_named).times(2).with(:blah).returns('item attr blah')
    item.expects(:attribute_named).with(:'blah!').returns('item attr blah!')

    # Get item proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal('item rep web path',       item_proxy.path)
    assert_equal(Time.parse('2008-05-19'),  item_proxy.mtime)
    assert_equal('item attr blah',          item_proxy.blah)
    assert_equal('item attr blah',          item_proxy.blah?)
    assert_equal('item attr blah!',         item_proxy.blah!)
  end

  def test_reps
    # Get item reps
    item_rep_0 = mock
    item_rep_0.expects(:name).at_least_once.returns(:default)
    item_rep_0.expects(:attribute_named).with(:foo).returns('bar')
    item_rep_1 = mock
    item_rep_1.expects(:name).at_least_once.returns(:raw)
    item_rep_1.expects(:attribute_named).with(:baz).returns('quux')

    # Get item reps proxies
    item_rep_0_proxy = Nanoc3::ItemRepProxy.new(item_rep_0)
    item_rep_0.expects(:to_proxy).returns(item_rep_0_proxy)
    item_rep_1_proxy = Nanoc3::ItemRepProxy.new(item_rep_1)
    item_rep_1.expects(:to_proxy).returns(item_rep_1_proxy)

    # Get item
    item = mock
    item.expects(:reps).times(2).returns([ item_rep_0, item_rep_1 ])

    # Get item proxy
    item_proxy = Nanoc3::ItemProxy.new(item)

    # Test
    assert_equal('bar',  item_proxy.reps(:default).foo)
    assert_equal('quux', item_proxy.reps(:raw).baz)
  end

end
