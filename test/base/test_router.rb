require 'test/helper'

class Nanoc3::RouterTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_path_for_item_rep
    # Create router
    router = Nanoc3::Router.new(nil)

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      router.path_for_item_rep(nil)
    end
  end

  def test_raw_path_for_without_custom_path
    # Create item and item rep
    item = Nanoc3::Item.new('content', {}, '/foobar/')
    item_rep = Nanoc3::ItemRep.new(item, :foo)

    # Mock site
    site = mock
    site.expects(:config).returns({ :output_dir => 'out' })

    # Create router
    router = Nanoc3::Router.new(site)
    router.expects(:path_for_item_rep).with(item_rep).returns('/foo.html')

    # Check
    assert_equal('out/foo.html', router.raw_path_for(item_rep))
  end

  def test_raw_path_for_with_custom_path
    # Create item and item rep
    item = Nanoc3::Item.new('content', { :custom_path => '/foo.html' }, '/foobar/')
    item_rep = Nanoc3::ItemRep.new(item, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({:output_dir => 'out'})

    # Create router
    router = Nanoc3::Router.new(site)

    # Check
    assert_equal('out/foo.html', router.raw_path_for(item_rep))
  end

  def test_path_for_without_custom_path_without_index
    # Create item and item rep
    item = Nanoc3::Item.new('content', {}, '/foobar/')
    item_rep = Nanoc3::ItemRep.new(item, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)
    router.expects(:path_for_item_rep).with(item_rep).returns('/foo.html')

    # Check
    assert_equal('/foo.html', router.path_for(item_rep))
  end

  def test_path_for_with_custom_path_without_index
    # Create item and item rep
    item = Nanoc3::Item.new('content', { :custom_path => '/foo.html' }, '/foobar/')
    item_rep = Nanoc3::ItemRep.new(item, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)

    # Check
    assert_equal('/foo.html', router.path_for(item_rep))
  end

  def test_path_for_without_custom_path_with_index
    # Create item and item rep
    item = Nanoc3::Item.new('content', {}, '/foobar/')
    item_rep = Nanoc3::ItemRep.new(item, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)
    router.expects(:path_for_item_rep).with(item_rep).returns('/foo/index.html')

    # Check
    assert_equal('/foo/', router.path_for(item_rep))
  end

  def test_path_for_with_custom_path_with_index
    # Create item and item rep
    item = Nanoc3::Item.new('content', { :custom_path => '/foo/index.html' }, '/foobar/')
    item_rep = Nanoc3::ItemRep.new(item, :foo)

    # Create site
    site = mock
    site.expects(:config).returns({
      :output_dir       => 'out',
      :index_filenames  => [ 'index.html' ]
    })

    # Create router
    router = Nanoc3::Router.new(site)

    # Check
    assert_equal('/foo/', router.path_for(item_rep))
  end

end
