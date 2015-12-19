class Nanoc::Helpers::TaggingTest < Nanoc::TestCase
  include Nanoc::Helpers::Tagging

  def view_context
    dependency_tracker = Nanoc::Int::DependencyTracker.new(nil)
    Nanoc::ViewContext.new(reps: nil, items: nil, dependency_tracker: dependency_tracker)
  end

  def test_tags_for_without_tags
    # Create item
    item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('content', {}, '/path/'), view_context)

    # Check
    assert_equal(
      '(none)',
      tags_for(item, base_url: 'http://example.com/tag/'),
    )
  end

  def test_tags_for_with_custom_base_url
    # Create item
    item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('content', { tags: %w(foo bar) }, '/path/'), view_context)

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://stoneship.org/tag/')}, " \
      "#{link_for_tag('bar', 'http://stoneship.org/tag/')}",
      tags_for(item, base_url: 'http://stoneship.org/tag/'),
    )
  end

  def test_tags_for_with_custom_none_text
    # Create item
    item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('content', { tags: [] }, '/path/'), view_context)

    # Check
    assert_equal(
      'no tags for you, fool',
      tags_for(item, none_text: 'no tags for you, fool', base_url: 'http://example.com/tag/'),
    )
  end

  def test_tags_for_with_custom_separator
    # Create item
    item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('content', { tags: %w(foo bar) }, '/path/'), view_context)

    # Check
    assert_equal(
      "#{link_for_tag('foo', 'http://example.com/tag/')} ++ " \
      "#{link_for_tag('bar', 'http://example.com/tag/')}",
      tags_for(item, separator: ' ++ ', base_url: 'http://example.com/tag/'),
    )
  end

  def test_tags_for_without_base_url
    # Create item
    item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('content', { tags: %w(foo bar) }, '/path/'), view_context)

    # Check
    assert_equal('foo, bar', tags_for(item))
  end

  def test_items_with_tag
    # Create items
    @items = Nanoc::ItemCollectionWithRepsView.new(
      [
        Nanoc::Int::Item.new('item 1', { tags: [:foo]       }, '/item1/'),
        Nanoc::Int::Item.new('item 2', { tags: [:bar]       }, '/item2/'),
        Nanoc::Int::Item.new('item 3', { tags: [:foo, :bar] }, '/item3/'),
      ],
      view_context,
    )

    # Find items
    items_with_foo_tag = items_with_tag(:foo)

    # Check
    assert_equal(
      [@items[0], @items[2]],
      items_with_foo_tag,
    )
  end

  def test_link_for_tag
    assert_equal(
      %(<a href="http://stoneship.org/tags/foobar" rel="tag">foobar</a>),
      link_for_tag('foobar', 'http://stoneship.org/tags/'),
    )
  end

  def test_link_for_tag_escape
    assert_equal(
      %(<a href="http://stoneship.org/tags&amp;stuff/foo&amp;bar" rel="tag">foo&amp;bar</a>),
      link_for_tag('foo&bar', 'http://stoneship.org/tags&stuff/'),
    )
  end
end
