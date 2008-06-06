require 'helper'

class Nanoc::EnhancementsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestSite

    def config
      @config ||= {}
    end

    def pages
      @pages ||= []
    end

    def layouts
      @layouts ||= [
        Nanoc::Layout.new(
          'Hi, this is the <%= @page.title %> page',
          { :filter => 'erb' },
          '/foo/'
        ),
        Nanoc::Layout.new(
          'layout content',
          { :filter => 'asdfsf' },
          '/bar/'
        ),
        Nanoc::Layout.new(
          'Foo <%= @middle %> Baz',
          { :filter => 'erb' },
          '/baz/'
        ),
      ]
    end

  end

  def test_in_dir
    # Initialize
    current_dir = Dir.getwd

    # Go into a lower dir
    in_dir([ 'lib' ]) do
      assert_equal(File.join([ current_dir, 'lib' ]), Dir.getwd)
    end
  end

  def test_render
    # Initialize
    @site     = TestSite.new
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
    # Initialize
    @site     = TestSite.new
    @page     = Nanoc::Page.new('page content', { :title => 'Sample' }, '/')
    @page_rep = Nanoc::PageRep.new(@page, {}, :default)
    @page.reps << @page_rep

    # Convert to proxy
    @page     = @page.to_proxy
    @page_rep = @page_rep.to_proxy

    # Render
    assert_nothing_raised do
      assert_equal('Foo Bar Baz', render('/baz/', :middle => 'Bar'))
    end
  end

  def test_render_with_unknown_layout
    # Initialize
    @site     = TestSite.new
    @page     = Nanoc::Page.new('page content', {}, '/')
    @page_rep = Nanoc::PageRep.new(@page, {}, :default)

    # Render
    assert_raise(Nanoc::Errors::UnknownLayoutError) do
      render '/blah/'
    end
  end

  def test_render_with_unknown_filter
    # Initialize
    @site     = TestSite.new
    @page     = Nanoc::Page.new('page content', {}, '/')
    @page_rep = Nanoc::PageRep.new(@page, {}, :default)

    # Render
    assert_raise(Nanoc::Errors::CannotDetermineFilterError) do
      render '/bar/'
    end
  end

end
