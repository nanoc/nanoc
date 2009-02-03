require 'test/helper'

class Nanoc::ItemRepProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get
    # Get item
    item = mock

    # Get item proxy
    item_proxy = mock
    item_proxy.expects(:moo).returns('item attr moo')
    item.expects(:to_proxy).returns(item_proxy)

    # Get item rep
    item_rep = mock
    item_rep.expects(:name).returns('item rep name')
    item_rep.expects(:item).returns(item)
    item_rep.expects(:content).returns('item rep content')
    item_rep.expects(:web_path).returns('item rep web path')
    item_rep.expects(:attribute_named).times(2).with(:blah).returns('item rep attr blah')
    item_rep.expects(:attribute_named).with(:'blah!').returns('item rep attr blah!')

    # Get item rep proxy
    item_rep_proxy = Nanoc::ItemRepProxy.new(item_rep)

    # Test
    assert_equal('item rep name',         item_rep_proxy.name)
    assert_equal('item rep content',      item_rep_proxy.content)
    assert_equal('item attr moo',         item_rep_proxy.item.moo)
    assert_equal('item rep web path',     item_rep_proxy.path)
    assert_equal('item rep attr blah',    item_rep_proxy.blah)
    assert_equal('item rep attr blah',    item_rep_proxy.blah?)
    assert_equal('item rep attr blah!',   item_rep_proxy.blah!)
  end

end
