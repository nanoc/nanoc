require 'test/helper'

class Nanoc3::LayoutTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_initialize
    # Make sure attributes are cleaned
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, layout.attributes)

    # Make sure identifier is cleaned
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', layout.identifier)
  end

  def test_to_proxy
    # Create layout
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, layout.attributes)

    # Create proxy
    layout_proxy = layout.to_proxy

    # Check values
    assert_equal('bar', layout_proxy.foo)
  end

  def test_attribute_named_with_known_attribute
    # Create layout
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal('bar', layout.attribute_named(:foo))
  end

  def test_attribute_named_with_unknown_attribute
    # Create layout
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal(nil, layout.attribute_named(:filter))
  end

end
