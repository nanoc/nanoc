require 'test/helper'

class Nanoc::Helpers::RenderTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Render

  def test_render
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:path,         '/foo/')
    layout.expect(:content,      'This is the <%= "foo" %> layout.')
    layout.expect(:filter_class, Nanoc::Filters::ERB)

    # Mock site, compiler and stack
    stack    = []
    compiler = MiniTest::Mock.new.expect(:stack, stack)
    @site    = MiniTest::Mock.new.expect(:compiler, compiler).expect(:layouts, [ layout ])

    # Render
    assert_equal('This is the foo layout.', render('/foo/'))
  end

  def test_render_with_unknown_layout
    # Mock site
    @site = MiniTest::Mock.new.expect(:layouts, [])

    # Render
    assert_raise(Nanoc::Errors::UnknownLayoutError) do
      render('/fawgooafwagwfe/')
    end
  end

  def test_render_with_unknown_filter
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:path,         '/foo/')
    layout.expect(:content,      'This is the <%= "foo" %> layout.')
    layout.expect(:filter_class, nil)

    # Mock site
    @site = MiniTest::Mock.new.expect(:layouts, [ layout ])

    # Render
    assert_raise(Nanoc::Errors::CannotDetermineFilterError) do
      render '/foo/'
    end
  end

end
