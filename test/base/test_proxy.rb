require 'test/helper'

class Nanoc::ProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_remove_methods
    # Create object and proxy
    obj = mock
    obj.expects(:attribute_named).with(:class).returns('no attr class')
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check removed methods
    assert_equal('no attr class', obj_proxy.class)
  end

  def test_get_with_symbol
    # Create object and proxy
    obj = mock
    obj.expects(:attribute_named).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy[:foo])
  end

  def test_get_with_string
    # Create object and proxy
    obj = mock
    obj.expects(:attribute_named).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy['foo'])
  end

  def test_get_with_question_mark
    # Create object and proxy
    obj = mock
    obj.expects(:attribute_named).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy['foo?'])
  end

  def test_set
    # Create object and proxy
    attributes = mock
    attributes.expects(:'[]=').with(:foo, 'new value')
    obj = mock
    obj.expects(:attributes).returns(attributes)
    obj.expects(:attribute_named).with(:foo).returns('new value')
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    obj_proxy[:foo] = 'new value'
    assert_equal('new value', obj_proxy['foo'])
  end

  def test_method_missing
    # Create object and proxy
    obj = mock
    obj.expects(:attribute_named).with(:foo).returns('no attr foo')
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attr foo', obj_proxy.foo)
  end

end
