require 'helper'

class Nanoc::LayoutTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource

    attr_reader :save_called, :move_called, :delete_called, :was_loaded

    def initialize
      @save_called    = false
      @move_called    = false
      @delete_called  = false
      @references     = 0
      @was_loaded     = false
    end

    def loading
      # Load if necessary
      up if @references == 0
      @references += 1

      yield
    ensure
      # Unload if necessary
      @references -= 1
      down if @references == 0
    end

    def up
      @was_loaded = true
    end

    def down
    end
 
    def save_layout(layout)
      @save_called = true
    end

    def move_layout(layout, new_path)
      @move_called = true
    end

    def delete_layout(layout)
      @delete_called = true
    end

  end

  class TestSite

    def data_source
      @data_source ||= TestDataSource.new
    end

  end

  def test_initialize
    # Make sure attributes are cleaned
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, layout.attributes)

    # Make sure path is fixed
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', layout.path)
  end

  def test_to_proxy
    # Create layout
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, layout.attributes)

    # Create proxy
    layout_proxy = layout.to_proxy

    # Check values
    assert_equal('bar', layout_proxy.foo)
  end

  def test_attribute_named
    # Create layout
    layout = Nanoc::Layout.new("content", { 'foo' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal({ :foo => 'bar' }, layout.attributes)
    assert_equal('bar', layout.attribute_named(:foo))
    assert_equal('erb', layout.attribute_named(:filter))

    # Create layout
    layout = Nanoc::Layout.new("content", { 'filter' => 'bar' }, '/foo/')

    # Check attributes
    assert_equal({ :filter => 'bar' }, layout.attributes)
    assert_equal(nil,   layout.attribute_named(:foo))
    assert_equal('bar', layout.attribute_named(:filter))
  end

  def test_filter_class
    # Check existant filter class
    layout = Nanoc::Layout.new("content", { 'filter' => 'erb' }, '/foo/')
    assert_equal(Nanoc::Filters::ERB, layout.filter_class)

    # Check nonexistant filter class
    layout = Nanoc::Layout.new("content", { 'filter' => 'klasdfhl' }, '/foo/')
    assert_equal(nil, layout.filter_class)
  end

  def test_save
    # Create site
    site = TestSite.new

    # Create layout
    layout = Nanoc::Layout.new("content", { :attr => 'ibutes'}, '/path/')
    layout.site = site

    # Save
    assert(!site.data_source.save_called)
    assert(!site.data_source.was_loaded)
    layout.save
    assert(site.data_source.save_called)
    assert(site.data_source.was_loaded)
  end

  def test_move_to
    # Create site
    site = TestSite.new

    # Create layout
    layout = Nanoc::Layout.new("content", { :attr => 'ibutes'}, '/path/')
    layout.site = site

    # Move
    assert(!site.data_source.move_called)
    assert(!site.data_source.was_loaded)
    layout.move_to('/new_path/')
    assert(site.data_source.move_called)
    assert(site.data_source.was_loaded)
  end

  def test_delete
    # Create site
    site = TestSite.new

    # Create layout
    layout = Nanoc::Layout.new("content", { :attr => 'ibutes'}, '/path/')
    layout.site = site

    # Delete
    assert(!site.data_source.delete_called)
    assert(!site.data_source.was_loaded)
    layout.delete
    assert(site.data_source.delete_called)
    assert(site.data_source.was_loaded)
  end

end
