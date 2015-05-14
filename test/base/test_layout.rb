# encoding: utf-8

class Nanoc::Int::LayoutTest < Nanoc::TestCase
  def test_initialize
    # Make sure attributes are cleaned
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, '/foo/')
    assert_equal({ foo: 'bar' }, layout.attributes)

    # Make sure identifier is cleaned
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, 'foo')
    assert_equal(Nanoc::Identifier.new('/foo/'), layout.identifier)
  end

  def test_lookup_with_known_attribute
    # Create layout
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal('bar', layout[:foo])
  end

  def test_lookup_with_unknown_attribute
    # Create layout
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal(nil, layout[:filter])
  end
end
