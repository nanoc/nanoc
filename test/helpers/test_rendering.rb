# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::RenderingTest < Nanoc3::TestCase

  include Nanoc3::Helpers::Rendering

  def test_render
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:identifier,   '/foo/')
    layout.expect(:raw_content,  'This is the <%= @layout.identifier %> layout.')

    # Mock site, compiler and stack
    compiler = MiniTest::Mock.new
    compiler.expects(:filter_for_layout).with(layout).returns([ :erb, {} ])
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
    assert_raises(Nanoc3::Errors::UnknownLayout) do
      render('/fawgooafwagwfe/')
    end
  end

  def test_render_without_filter
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:identifier,   '/foo/')
    layout.expect(:raw_content,  'This is the <%= "foo" %> layout.')

    # Mock compiler
    compiler = mock
    compiler.stubs(:filter_for_layout).with(layout).returns(nil)

    # Mock site
    @site = MiniTest::Mock.new
    @site.expect(:layouts, [ layout ])
    @site.expect(:compiler, compiler)

    # Render
    assert_raises(Nanoc3::Errors::CannotDetermineFilter) do
      render '/foo/'
    end
  end

  def test_render_with_unknown_filter
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:identifier,   '/foo/')
    layout.expect(:raw_content,  'This is the <%= "foo" %> layout.')

    # Mock compiler
    compiler = mock
    compiler.stubs(:filter_for_layout).with(layout).returns([ :kjsdalfjwagihlawfji, {} ])

    # Mock site
    @site = MiniTest::Mock.new
    @site.expect(:layouts, [ layout ])
    @site.expect(:compiler, compiler)

    # Render
    assert_raises(Nanoc3::Errors::UnknownFilter) do
      render '/foo/'
    end
  end

  def test_render_with_block
    # Mock layouts
    layout = MiniTest::Mock.new
    layout.expect(:identifier,   '/foo/')
    layout.expect(:raw_content,  '[partial-before]<%= yield %>[partial-after]')

    # Mock compiler
    compiler = mock
    compiler.expects(:filter_for_layout).with(layout).returns([ :erb, {} ])

    # Mock site
    @site    = MiniTest::Mock.new
    @site.expect(:compiler, compiler)
    @site.expect(:layouts, [ layout ])

    # Mock erbout
    _erbout = '[erbout-before]'

    # Render
    render '/foo/' do
      _erbout << "This is some extra content"
    end
    assert_equal('[erbout-before][partial-before]This is some extra content[partial-after]', _erbout)
  end

end
