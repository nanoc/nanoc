require 'helper'

class Nanoc::PageTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Make sure attributes are cleaned
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, page.attributes)

    # Make sure path is fixed
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', page.path)
  end

  def test_build_reps
    # TODO implement
  end

  def test_to_proxy
    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, page.attributes)

    # Create proxy
    page_proxy = page.to_proxy

    # Check values
    assert_equal('bar', page_proxy.foo)
  end

  def test_attribute_named
    in_dir [ 'tmp' ] do
      # Create temporary site
      create_site('testing')

      in_dir [ 'testing' ] do
        # Get site
        site = Nanoc::Site.new({})

        # Create page defaults (hacky...)
        page_defaults = Nanoc::PageDefaults.new({ :quux => 'stfu' })
        site.instance_eval { @page_defaults = page_defaults }

        # Create page
        page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
        page.site = site

        # Test
        assert_equal('bar',  page.attribute_named(:foo))
        assert_equal('html', page.attribute_named(:extension))
        assert_equal('stfu', page.attribute_named(:quux))

        # Create page
        page = Nanoc::Page.new("content", { 'extension' => 'php' }, '/foo/')
        page.site = site

        # Test
        assert_equal(nil,    page.attribute_named(:foo))
        assert_equal('php',  page.attribute_named(:extension))
        assert_equal('stfu', page.attribute_named(:quux))
      end
    end
  end

  def test_save
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:save_page).with(page)

    # Save
    page.save
  end

  def test_move_to
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:move_page).with(page, '/new_path/')

    # Move
    page.move_to('/new_path/')
  end

  def test_delete
    # Create site
    site = mock

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes' }, '/path/')
    page.site = site

    # Create data source
    data_source = mock
    site.stubs(:data_source).returns(data_source)
    data_source.expects(:loading).yields
    data_source.expects(:delete_page).with(page)

    # Delete
    page.delete
  end

end
