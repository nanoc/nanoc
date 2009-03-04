require 'test/helper'

class Nanoc::LayoutProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get
    # Get layout
    layout = mock
    layout.expects(:content).returns('layout content')
    layout.expects(:identifier).returns('layout identifier')
    layout.expects(:mtime).returns(Time.parse('2008-05-19'))
    layout.expects(:attribute_named).times(2).with(:blah).returns('layout attr blah')
    layout.expects(:attribute_named).with(:'blah!').returns('layout attr blah!')

    # Get layout proxy
    layout_proxy = Nanoc::LayoutProxy.new(layout)

    # Test
    assert_equal('layout content',          layout_proxy.content)
    assert_equal('layout identifier',       layout_proxy.identifier)
    assert_equal(Time.parse('2008-05-19'),  layout_proxy.mtime)
    assert_equal('layout attr blah',        layout_proxy.blah)
    assert_equal('layout attr blah',        layout_proxy.blah?)
    assert_equal('layout attr blah!',       layout_proxy.blah!)
  end

end
