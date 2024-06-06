# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::MustacheTest < Nanoc::TestCase
  def test_filter
    # Create item
    item = Nanoc::Core::Item.new(
      'content',
      { title: 'Max Payne', protagonist: 'Max Payne' },
      '/games/max-payne',
    )

    # Create filter
    filter = ::Nanoc::Filters::Mustache.new(item:)

    # Run filter
    result = filter.setup_and_run('The protagonist of {{title}} is {{protagonist}}.')

    assert_equal('The protagonist of Max Payne is Max Payne.', result)
  end

  def test_filter_with_yield
    # Create item
    item = Nanoc::Core::Item.new(
      'content',
      { title: 'Max Payne', protagonist: 'Max Payne' },
      '/games/max-payne',
    )

    # Create filter
    filter = ::Nanoc::Filters::Mustache.new(
      content: 'No Payne No Gayne', item:,
    )

    # Run filter
    result = filter.setup_and_run('Max says: {{yield}}.')

    assert_equal('Max says: No Payne No Gayne.', result)
  end
end
