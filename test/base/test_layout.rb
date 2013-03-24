# encoding: utf-8

class Nanoc::LayoutTest < Nanoc::TestCase

  def test_initialize
    # Make sure attributes are cleaned
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, layout.attributes)

    # Make sure identifier is cleaned
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', layout.identifier)
  end

  def test_frozen_identifier
    layout = Nanoc::Layout.new("foo", {}, '/foo')

    assert_raises_frozen_error do
      layout.identifier.chop!
    end
  end

  def test_lookup_with_known_attribute
    # Create layout
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal('bar', layout[:foo])
  end

  def test_lookup_with_unknown_attribute
    # Create layout
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal(nil, layout[:filter])
  end

  def test_dump_and_load
    layout = Nanoc::Layout.new(
      "foobar",
      { :a => { :b => 123 }},
      '/foo/')

    layout = Marshal.load(Marshal.dump(layout))

    assert_equal '/foo/', layout.identifier
    assert_equal 'foobar', layout.raw_content
    assert_equal({ :a => { :b => 123 }}, layout.attributes)
  end

end
