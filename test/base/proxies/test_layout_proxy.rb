require 'test/helper'

class Nanoc3::LayoutProxyTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_get
    # Get layout
    layout = mock
    layout.expects(:content).returns('layout content')
    layout.expects(:identifier).returns('layout identifier')
    layout.expects(:mtime).returns(Time.parse('2008-05-19'))
    layout.expects(:[]).with(:'blah' ).returns('layout attr blah')
    layout.expects(:[]).with(:'blah?').returns('layout attr blah?')
    layout.expects(:[]).with(:'blah!').returns('layout attr blah!')

    # Get layout proxy
    layout_proxy = Nanoc3::LayoutProxy.new(layout)

    # Test
    assert_equal('layout content',          layout_proxy.content)
    assert_equal('layout identifier',       layout_proxy.identifier)
    assert_equal(Time.parse('2008-05-19'),  layout_proxy.mtime)
    assert_equal('layout attr blah',        layout_proxy.blah)
    assert_equal('layout attr blah?',       layout_proxy.blah?)
    assert_equal('layout attr blah!',       layout_proxy.blah!)
  end

end
