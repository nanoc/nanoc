# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::SlimTest < Nanoc::TestCase
  def test_filter
    if_have 'slim' do
      # Create filter
      filter = ::Nanoc::Filters::Slim.new(rabbit: 'The rabbit is on the branch.')

      # Run filter (no assigns)
      result = filter.setup_and_run('html')
      assert_match(/<html>.*<\/html>/, result)

      # Run filter (assigns without @)
      result = filter.setup_and_run('p = rabbit')
      assert_equal('<p>The rabbit is on the branch.</p>', result)

      # Run filter (assigns with @)
      result = filter.setup_and_run('p = @rabbit')
      assert_equal('<p>The rabbit is on the branch.</p>', result)
    end
  end

  def test_filter_with_yield
    if_have 'slim' do
      filter = ::Nanoc::Filters::Slim.new(content: 'The rabbit is on the branch.')

      result = filter.setup_and_run('p = yield')
      assert_equal('<p>The rabbit is on the branch.</p>', result)
    end
  end

  def new_view_context
    Nanoc::ViewContext.new(
      reps: :__irrelevat_reps,
      items: :__irrelevat_items,
      dependency_tracker: :__irrelevant_dependency_tracker,
      compilation_context: :__irrelevat_compiler,
      snapshot_repo: :__irrelevant_snapshot_repo,
    )
  end

  def test_filter_slim_reports_filename
    if_have 'slim' do
      layout = Nanoc::Int::Layout.new('', {}, '/layout.slim')
      layout = Nanoc::LayoutView.new(layout, new_view_context)

      assigns = { layout: layout }

      filter = ::Nanoc::Filters::Slim.new(assigns)

      error = assert_raises(NameError) { filter.setup_and_run('deliberate=failure') }
      assert_match(%r{^layout /layout.slim}, error.backtrace[1])
    end
  end
end
