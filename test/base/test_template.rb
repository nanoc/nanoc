require 'helper'

class Nanoc::TemplateTest < Test::Unit::TestCase

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

    def save_template(template)
      @save_called = true
    end

    def move_template(template, new_name)
      @move_called = true
    end

    def delete_template(template)
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
    template = Nanoc::Template.new('content', { 'foo' => 'bar' }, 'sample')
    assert_equal({ :foo => 'bar' }, template.page_attributes)
  end

  def test_save
    # Create site
    site = TestSite.new

    # Create template
    template = Nanoc::Template.new("content", { :attr => 'ibutes'}, 'name')
    template.site = site

    # Save
    assert(!site.data_source.save_called)
    assert(!site.data_source.was_loaded)
    template.save
    assert(site.data_source.save_called)
    assert(site.data_source.was_loaded)
  end

  def test_move_to
    # Create site
    site = TestSite.new

    # Create template
    template = Nanoc::Template.new("content", { :attr => 'ibutes'}, 'name')
    template.site = site

    # Move
    assert(!site.data_source.move_called)
    assert(!site.data_source.was_loaded)
    template.move_to('/new_name/')
    assert(site.data_source.move_called)
    assert(site.data_source.was_loaded)
  end

  def test_delete
    # Create site
    site = TestSite.new

    # Create template
    template = Nanoc::Template.new("content", { :attr => 'ibutes'}, 'name')
    template.site = site

    # Delete
    assert(!site.data_source.delete_called)
    assert(!site.data_source.was_loaded)
    template.delete
    assert(site.data_source.delete_called)
    assert(site.data_source.was_loaded)
  end

end
