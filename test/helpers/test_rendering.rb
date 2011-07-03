# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::RenderingTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Rendering

  def test_render
    # Mock layouts
    layout = Nanoc3::Layout.new(
      'This is the <%= @layout.identifier %> layout.',
      {},
      '/foo/')

    # Mock site, compiler and stack
    stack    = []
    compiler = MiniTest::Mock.new
    compiler.expect(:stack, stack)
    compiler.expect(:filter_for_layout, [ :erb, {} ], [ layout ])
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
    layout = Nanoc3::Layout.new(
      'This is the <%= @layout.identifier %> layout.',
      {},
      '/foo/')

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
    layout = Nanoc3::Layout.new(
      'This is the <%= @layout.identifier %> layout.',
      {},
      '/foo/')

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
    layout = Nanoc3::Layout.new(
       '[partial-before]<%= yield %>[partial-after]',
      {},
      '/foo/')

    # Mock compiler
    stack    = []
    compiler = mock
    compiler.stubs(:stack).returns(stack)
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
