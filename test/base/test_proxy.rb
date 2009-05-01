require 'test/helper'

class Nanoc3::ProxyTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_get_with_symbol
    # Create object and proxy
    obj = mock
    obj.expects(:[]).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc3::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy[:foo])
  end

  def test_get_with_string
    # Create object and proxy
    obj = mock
    obj.expects(:[]).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc3::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy['foo'])
  end

  def test_get_with_question_mark
    # Create object and proxy
    obj = mock
    obj.expects(:[]).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc3::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy['foo?'])
  end

  def test_set
    # Create object and proxy
    attributes = mock
    attributes.expects(:'[]=').with(:foo, 'new value')
    obj = mock
    obj.expects(:attributes).returns(attributes)
    obj.expects(:[]).with(:foo).returns('new value')
    obj_proxy = Nanoc3::Proxy.new(obj)

    # Check
    obj_proxy[:foo] = 'new value'
    assert_equal('new value', obj_proxy['foo'])
  end

  def test_method_missing
    # Create object and proxy
    obj = mock
    obj.expects(:[]).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc3::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy.foo)
  end

end
