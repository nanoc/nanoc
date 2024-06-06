# frozen_string_literal: true

require 'helper'

class Nanoc::Filters::SlimTest < Nanoc::TestCase
  def test_filter
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

  def test_filter_with_yield
    filter = ::Nanoc::Filters::Slim.new(content: 'The rabbit is on the branch.')

    result = filter.setup_and_run('p = yield')

    assert_equal('<p>The rabbit is on the branch.</p>', result)
  end

  def new_view_context
    config = Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults

    items = Nanoc::Core::ItemCollection.new(config)
    layouts = Nanoc::Core::LayoutCollection.new(config)
    reps = Nanoc::Core::ItemRepRepo.new

    site =
      Nanoc::Core::Site.new(
        config:,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )

    compiled_content_cache = Nanoc::Core::CompiledContentCache.new(config:)
    compiled_content_store = Nanoc::Core::CompiledContentStore.new

    action_provider =
      Class.new(Nanoc::Core::ActionProvider) do
        def self.for(_context)
          raise NotImplementedError
        end

        def initialize; end
      end.new

    compilation_context =
      Nanoc::Core::CompilationContext.new(
        action_provider:,
        reps:,
        site:,
        compiled_content_cache:,
        compiled_content_store:,
      )

    Nanoc::Core::ViewContextForCompilation.new(
      reps: Nanoc::Core::ItemRepRepo.new,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker: Nanoc::Core::DependencyTracker::Null.new,
      compilation_context:,
      compiled_content_store:,
    )
  end

  def test_filter_slim_reports_filename
    layout = Nanoc::Core::Layout.new('', {}, '/layout.slim')
    layout = Nanoc::Core::LayoutView.new(layout, new_view_context)

    assigns = { layout: }

    filter = ::Nanoc::Filters::Slim.new(assigns)

    error = assert_raises(NameError) { filter.setup_and_run('deliberate=failure') }

    assert_match(%r{^layout /layout.slim}, error.backtrace[1])
  end
end
