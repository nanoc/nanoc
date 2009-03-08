require 'test/helper'

class Nanoc::Helpers::RenderTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Render

  def test_render
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:identifier,   '/foo/')
    layout.expect(:content,      'This is the <%= @layout.path %> layout.')
    layout_proxy = MiniTest::Mock.new
    layout_proxy.expect(:path, '/foo/')
    layout.expect(:to_proxy, layout_proxy)

    # Mock site, compiler and stack
    stack    = []
    compiler = MiniTest::Mock.new
    compiler.expect(:stack, stack)
    compiler.expects(:filter_class_for_layout).with(layout).returns(Nanoc::Filters::ERB)
    @site    = MiniTest::Mock.new
    @site.expect(:compiler, compiler)
    @site.expect(:layouts, [ layout ])

    # Render
    assert_equal('This is the /foo/ layout.', render('/foo/'))
  end

  def test_render_with_unknown_layout
    # Mock site
    @site = MiniTest::Mock.new.expect(:layouts, [])

    # Render
    assert_raises(Nanoc::Errors::UnknownLayoutError) do
      render('/fawgooafwagwfe/')
    end
  end

  def test_render_with_unknown_filter
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:identifier,   '/foo/')
    layout.expect(:content,      'This is the <%= "foo" %> layout.')
    layout_proxy = MiniTest::Mock.new
    layout.expect(:to_proxy, layout_proxy)

    # Mock compiler
    compiler = mock
    compiler.expects(:filter_class_for_layout).with(layout).raises(Nanoc::Errors::UnknownFilterError)

    # Mock site
    @site = MiniTest::Mock.new
    @site.expect(:layouts, [ layout ])
    @site.expect(:compiler, compiler)

    # Render
    assert_raises(Nanoc::Errors::UnknownFilterError) do
      render '/foo/'
    end
  end

end
