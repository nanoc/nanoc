require 'test/helper'

class Nanoc::RouterTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_path_for_page_rep
    # Create router
    router = Nanoc::Router.new(nil)

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      router.path_for_page_rep(nil)
    end
  end

  def test_path_for_asset_rep
    # Create router
    router = Nanoc::Router.new(nil)

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      router.path_for_asset_rep(nil)
    end
  end

  def test_disk_path_for_without_cp_without_index
    # Create page
    page_rep = mock
    page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    page_rep.expects(:attribute_named).with(:custom_path).returns(nil)

    # Create site
    site = mock
    site.expects(:config).returns({:output_dir => 'tmp/out'})

    # Create router
    router = Nanoc::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo.html')

    # Check
    assert_equal('tmp/out/foo.html', router.disk_path_for(page_rep))
  end

  def test_disk_path_for_with_cp_without_index
    # Create page
    page_rep = mock
    page_rep.expects(:attribute_named).with(:custom_path).returns('/foo.html')

    # Create site
    site = mock
    site.expects(:config).returns({:output_dir => 'tmp/out'})

    # Create router
    router = Nanoc::Router.new(site)

    # Check
    assert_equal('tmp/out/foo.html', router.disk_path_for(page_rep))
  end

  def test_disk_path_for_without_cp_with_index
    # Create page
    page_rep = mock
    page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    page_rep.expects(:attribute_named).with(:custom_path).returns(nil)

    # Create site
    site = mock
    site.expects(:config).returns({:output_dir => 'tmp/out'})

    # Create router
    router = Nanoc::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo/index.html')

    # Check
    assert_equal('tmp/out/foo/index.html', router.disk_path_for(page_rep))
  end

  def test_disk_path_for_with_cp_with_index
    # Create page
    page_rep = mock
    page_rep.expects(:attribute_named).with(:custom_path).returns('/foo/index.html')

    # Create site
    site = mock
    site.expects(:config).returns({:output_dir => 'tmp/out'})

    # Create router
    router = Nanoc::Router.new(site)

    # Check
    assert_equal('tmp/out/foo/index.html', router.disk_path_for(page_rep))
  end

  def test_web_path_for_without_cp_without_index
    # Create page
    page_rep = mock
    page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    page_rep.expects(:attribute_named).with(:custom_path).returns(nil)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'tmp/out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo.html')

    # Check
    assert_equal('/foo.html', router.web_path_for(page_rep))
  end

  def test_web_path_for_with_cp_without_index
    # Create page
    page_rep = mock
    page_rep.expects(:attribute_named).with(:custom_path).returns('/foo.html')

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'tmp/out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc::Router.new(site)

    # Check
    assert_equal('/foo.html', router.web_path_for(page_rep))
  end

  def test_web_path_for_without_cp_with_index
    # Create page
    page_rep = mock
    page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    page_rep.expects(:attribute_named).with(:custom_path).returns(nil)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'tmp/out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc::Router.new(site)
    router.expects(:path_for_page_rep).with(page_rep).returns('/foo/index.html')

    # Check
    assert_equal('/foo/', router.web_path_for(page_rep))
  end

  def test_web_path_for_with_cp_with_index
    # Create page
    page_rep = mock
    page_rep.expects(:attribute_named).with(:custom_path).returns('/foo/index.html')

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'tmp/out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc::Router.new(site)

    # Check
    assert_equal('/foo/', router.web_path_for(page_rep))
  end

end
