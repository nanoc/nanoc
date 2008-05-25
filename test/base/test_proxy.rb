require 'helper'

class ProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestProxy

    def attribute_named(key)
      @attributes ||= {}
      @attributes[key] || "no attribute named #{key}"
    end

    def attributes
      @attributes ||= {}
    end

  end

  def test_remove_methods
    # Create object and proxy
    obj = TestProxy.new
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check removed methods
    assert_equal('no attribute named class', obj_proxy.class)
  end

  def test_get_with_symbol
    # Create object and proxy
    obj = TestProxy.new
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attribute named foo', obj_proxy[:foo])
  end

  def test_get_with_string
    # Create object and proxy
    obj = TestProxy.new
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attribute named foo', obj_proxy['foo'])
  end

  def test_get_with_question_mark
    # Create object and proxy
    obj = TestProxy.new
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attribute named foo', obj_proxy['foo?'])
  end

  def test_set
    # Create object and proxy
    obj = TestProxy.new
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attribute named foo', obj_proxy['foo'])
    obj_proxy[:foo] = 'there is a foo'
    assert_equal('there is a foo', obj_proxy['foo'])
  end

  def test_method_missing
    # Create object and proxy
    obj = TestProxy.new
    obj_proxy = Nanoc::Proxy.new(obj)

    # Check
    assert_equal('no attribute named foo', obj_proxy.foo)
  end

end
