# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::KramdownTest < Nanoc::TestCase
  def test_filter
    # Create filter
    filter = ::Nanoc::Filters::Kramdown.new

    # Run filter
    result = filter.setup_and_run('This is _so_ **cool**!')

    assert_equal("<p>This is <em>so</em> <strong>cool</strong>!</p>\n", result)
  end

  def test_warnings
    # Create item
    item = Nanoc::Core::Item.new('foo', {}, '/foo.md')
    item_view = Nanoc::Core::CompilationItemView.new(item, nil)
    item_rep = Nanoc::Core::ItemRep.new(item, :default)
    item_rep_view = Nanoc::Core::CompilationItemRepView.new(item_rep, nil)

    # Create filter
    filter = ::Nanoc::Filters::Kramdown.new(item: item_view, item_rep: item_rep_view)

    # Run filter
    io = capturing_stdio do
      filter.setup_and_run('{:foo}this is bogus')
    end

    assert_empty io[:stdout]
    assert_equal "kramdown warning(s) for #{item_rep_view.inspect}\n  Found span IAL after text - ignoring it\n", io[:stderr]
  end

  def test_warning_filters
    # Create item
    item = Nanoc::Core::Item.new('foo', {}, '/foo.md')
    item_view = Nanoc::Core::CompilationItemView.new(item, nil)
    item_rep = Nanoc::Core::ItemRep.new(item, :default)
    item_rep_view = Nanoc::Core::CompilationItemRepView.new(item_rep, nil)

    # Create filter
    filter = ::Nanoc::Filters::Kramdown.new(item: item_view, item_rep: item_rep_view)

    # Run filter
    io = capturing_stdio do
      filter.setup_and_run("{:foo}this is bogus\n[foo]: http://foo.com\n", warning_filters: 'No link definition')
    end

    assert_empty io[:stdout]
    assert_equal "kramdown warning(s) for #{item_rep_view.inspect}\n  Found span IAL after text - ignoring it\n", io[:stderr]
  end
end
