require 'test/helper'

class Nanoc3::RouterTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_path_for_page_rep
    # Create router
    router = Nanoc3::Router.new(nil)

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      router.path_for_page_rep(nil)
    end
  end

  def test_path_for_asset_rep
    # Create router
    router = Nanoc3::Router.new(nil)

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      router.path_for_asset_rep(nil)
    end
  end

  def test_raw_path_for_without_custom_path
    # Create page and page rep
    page = Nanoc3::Page.new('content', {}, '/foobar/')
    page_rep = Nanoc3::PageRep.new(page, :foo)

    # Mock site
    site = mock
    site.expects(:config).returns({ :output_dir => 'out' })

    # Create router
    router = Nanoc3::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo.html')

    # Check
    assert_equal('out/foo.html', router.raw_path_for(page_rep))
  end

  def test_raw_path_for_with_custom_path
    # Create page and page rep
    page = Nanoc3::Page.new('content', { :custom_path => '/foo.html' }, '/foobar/')
    page_rep = Nanoc3::PageRep.new(page, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({:output_dir => 'out'})

    # Create router
    router = Nanoc3::Router.new(site)

    # Check
    assert_equal('out/foo.html', router.raw_path_for(page_rep))
  end

  def test_path_for_without_custom_path_without_index
    # Create page and page rep
    page = Nanoc3::Page.new('content', {}, '/foobar/')
    page_rep = Nanoc3::PageRep.new(page, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo.html')

    # Check
    assert_equal('/foo.html', router.path_for(page_rep))
  end

  def test_path_for_with_custom_path_without_index
    # Create page and page rep
    page = Nanoc3::Page.new('content', { :custom_path => '/foo.html' }, '/foobar/')
    page_rep = Nanoc3::PageRep.new(page, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)

    # Check
    assert_equal('/foo.html', router.path_for(page_rep))
  end

  def test_path_for_without_custom_path_with_index
    # Create page and page rep
    page = Nanoc3::Page.new('content', {}, '/foobar/')
    page_rep = Nanoc3::PageRep.new(page, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo/index.html')

    # Check
    assert_equal('/foo/', router.path_for(page_rep))
  end

  def test_path_for_with_custom_path_with_index
    # Create page and page rep
    page = Nanoc3::Page.new('content', { :custom_path => '/foo/index.html' }, '/foobar/')
    page_rep = Nanoc3::PageRep.new(page, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)

    # Check
    assert_equal('/foo/', router.path_for(page_rep))
  end

end
