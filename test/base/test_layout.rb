# encoding: utf-8

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

  def test_frozen_identifier
    layout = Nanoc3::Layout.new("foo", {}, '/foo')

    error = assert_raises(RuntimeError) do
      layout.identifier.chop!
    end
    assert_equal "can't modify frozen string", error.message
  end

  def test_lookup_with_known_attribute
    # Create layout
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal('bar', layout[:foo])
  end

  def test_lookup_with_unknown_attribute
    # Create layout
    layout = Nanoc3::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal(nil, layout[:filter])
  end

end
