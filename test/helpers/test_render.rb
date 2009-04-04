require 'test/helper'

class Nanoc::Helpers::RenderTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_render
    # Create layout
    layout = Nanoc::Layout.new(
      'Hi, this is the <%= @page.title %> page',
      { :filter => 'erb' },
      '/foo/'
    )

    # Create site
    site = mock
    # site.expects(:config).returns({})
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:layouts).times(2).returns([ layout ])
    site.expects(:config).returns({})
    compiler = mock
    compiler.expects(:stack).at_least_once.returns([])
    site.expects(:compiler).at_least_once.returns(compiler)

    # Create pages
    page = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    page.site = site
    page_rep = Nanoc::PageRep.new(page, {}, :default)
    page.reps << page_rep

    # Set object and its rep
    @_obj     = page
    @_obj_rep = page_rep

    # Render
    assert_equal('Hi, this is the Sample page', render('/foo/'))
  end

  def test_render_with_other_assigns
    # Create layout
    layout = Nanoc::Layout.new(
      'Foo <%= @middle %> Baz',
      { :filter => 'erb' },
      '/foo/'
    )

    # Create site
    site = mock
    # site.expects(:config).returns({})
    site.expects(:pages).returns([])
    site.expects(:assets).returns([])
    site.expects(:layouts).times(2).returns([ layout ])
    site.expects(:config).returns({})
    compiler = mock
    compiler.expects(:stack).at_least_once.returns([])
    site.expects(:compiler).at_least_once.returns(compiler)

    # Create pages
    page = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    page.site = site
    page_rep = Nanoc::PageRep.new(page, {}, :default)
    page.reps << page_rep

    # Set object and its rep
    @_obj     = page
    @_obj_rep = page_rep

    # Render
    assert_equal('Foo Bar Baz', render('/foo/', :middle => 'Bar'))
  end

  def test_render_with_unknown_layout
    # Create site
    site = mock
    site.expects(:layouts).returns([])

    # Create pages
    page = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    page.site = site
    page_rep = Nanoc::PageRep.new(page, {}, :default)
    page.reps << page_rep

    # Set object and its rep
    @_obj     = page
    @_obj_rep = page_rep

    # Render
    assert_raise(Nanoc::Errors::UnknownLayoutError) do
      render('/fawgooafwagwfe/')
    end
  end

  def test_render_with_unknown_filter
    # Create layout
    layout = Nanoc::Layout.new(
      'Foo',
      { :filter => 'afafedhrdjdhrwegfwe' },
      '/foo/'
    )

    # Create site
    site = mock
    site.expects(:layouts).returns([ layout ])

    # Create pages
    page = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    page.site = site
    page_rep = Nanoc::PageRep.new(page, {}, :default)
    page.reps << page_rep

    # Set object and its rep
    @_obj     = page
    @_obj_rep = page_rep

    # Render
    assert_raise(Nanoc::Errors::CannotDetermineFilterError) do
      render '/foo/'
    end
  end

end
