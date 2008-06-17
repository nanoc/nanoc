require 'helper'

class Nanoc::EnhancementsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_in_dir
    # Initialize
    current_dir = Dir.getwd

    # Go into a lower dir
    in_dir([ 'lib' ]) do
      assert_equal(File.join([ current_dir, 'lib' ]), Dir.getwd)
    end
  end

  def test_render
    # Create layout
    layout = Nanoc::Layout.new(
      'Hi, this is the <%= @page.title %> page',
      { :filter => 'erb' },
      '/foo/'
    )

    # Create site
    @site = mock
    @site.expects(:config).returns({})
    @site.expects(:pages).returns([])
    @site.expects(:assets).returns([])
    @site.expects(:layouts).times(2).returns([ layout ])
    compiler = mock
    compiler.expects(:stack).at_least_once.returns([])
    @site.expects(:compiler).at_least_once.returns(compiler)

    # Create pages
    @page     = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    @page_rep = Nanoc::PageRep.new(@page, {}, :default)
    @page.reps << @page_rep

    # Convert to proxy
    @page     = @page.to_proxy
    @page_rep = @page_rep.to_proxy

    # Render
    assert_nothing_raised do
      assert_equal('Hi, this is the Sample page', render('/foo/'))
    end
  end

  def test_render_with_other_assigns
    # Create layout
    layout = Nanoc::Layout.new(
      'Foo <%= @middle %> Baz',
      { :filter => 'erb' },
      '/foo/'
    )

    # Create site
    @site = mock
    @site.expects(:config).returns({})
    @site.expects(:pages).returns([])
    @site.expects(:assets).returns([])
    @site.expects(:layouts).times(2).returns([ layout ])
    compiler = mock
    compiler.expects(:stack).at_least_once.returns([])
    @site.expects(:compiler).at_least_once.returns(compiler)

    # Create pages
    @page     = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    @page_rep = Nanoc::PageRep.new(@page, {}, :default)
    @page.reps << @page_rep

    # Convert to proxy
    @page     = @page.to_proxy
    @page_rep = @page_rep.to_proxy

    # Render
    assert_nothing_raised do
      assert_equal('Foo Bar Baz', render('/foo/', :middle => 'Bar'))
    end
  end

  def test_render_with_unknown_layout
    # Create layout
    layout = Nanoc::Layout.new(
      'Foo',
      { :filter => 'erb' },
      '/foo/'
    )

    # Create site
    @site = mock
    @site.expects(:layouts).returns([ layout ])

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
    @site = mock
    @site.expects(:layouts).returns([ layout ])

    # Render
    assert_raise(Nanoc::Errors::CannotDetermineFilterError) do
      render '/foo/'
    end
  end

end
