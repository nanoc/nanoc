require 'helper'

class Nanoc::LayoutProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestLayout

    def content
      'layout content'
    end

    def path
      'layout path'
    end

    def attribute_named(key)
      "attribute named #{key}"
    end

  end

  def test_get
    # Get layout
    layout = TestLayout.new
    layout_proxy = Nanoc::LayoutProxy.new(layout)

    # Test
    assert_equal('layout content',        layout_proxy.content)
    assert_equal('layout path',           layout_proxy.path)
    assert_equal('attribute named blah',  layout_proxy.blah)
    assert_equal('attribute named blah',  layout_proxy.blah?)
    assert_equal('attribute named blah!', layout_proxy.blah!)
  end

end
