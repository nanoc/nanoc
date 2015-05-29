class Nanoc::Int::LayoutTest < Nanoc::TestCase
  def test_initialize
    # Make sure attributes are cleaned
    layout = Nanoc::Int::Layout.new('content', { 'foo' => 'bar' }, '/foo')
    assert_equal({ foo: 'bar' }, layout.attributes)
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

  def test_dump_and_load
    layout = Nanoc::Int::Layout.new(
      'foobar',
      { a: { b: 123 } },
      '/foo/')

    layout = Marshal.load(Marshal.dump(layout))

    assert_equal Nanoc::Identifier.new('/foo/'), layout.identifier
    assert_equal 'foobar', layout.raw_content
    assert_equal({ a: { b: 123 } }, layout.attributes)
  end
end
