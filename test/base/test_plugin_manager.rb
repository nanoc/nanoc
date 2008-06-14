require 'helper'

class Nanoc::PluginManagerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_data_source_right
    assert_nothing_raised do
      data_source = Nanoc::PluginManager.instance.data_source(:filesystem)
      assert(!data_source.nil?)
    end
  end

  def test_data_source_wrong
    assert_nothing_raised do
      data_source = Nanoc::PluginManager.instance.data_source(:lksdaffhdlkashlgkskahf)
      assert(data_source.nil?)
    end
  end

  def test_filter_right
    assert_nothing_raised do
      filter = Nanoc::PluginManager.instance.filter(:erb)
      assert(!filter.nil?)
    end
  end

  def test_filter_wrong
    assert_nothing_raised do
      filter = Nanoc::PluginManager.instance.filter(:lksdaffhdlkashlgkskahf)
      assert(filter.nil?)
    end
  end

  def test_binary_filter_right
    assert_nothing_raised do
      filter = Nanoc::PluginManager.instance.binary_filter(:thumbnail)
      assert(!filter.nil?)
    end
  end

  def test_binary_filter_wrong
    assert_nothing_raised do
      filter = Nanoc::PluginManager.instance.binary_filter(:lksdaffhd)
      assert(filter.nil?)
    end
  end

  def test_layout_processor_right
    assert_nothing_raised do
      layout_processor = Nanoc::PluginManager.instance.layout_processor('.erb')
      assert(!layout_processor.nil?)
    end
  end

  def test_layout_processor_wrong
    assert_nothing_raised do
      layout_processor = Nanoc::PluginManager.instance.layout_processor('.xxx')
      assert(layout_processor.nil?)
    end
  end

  def test_router_right
    assert_nothing_raised do
      router = Nanoc::PluginManager.instance.router(:default)
      assert(!router.nil?)
    end
  end

  def test_router_wrong
    assert_nothing_raised do
      router = Nanoc::PluginManager.instance.router(:lksdaffhdlkashlgkskahf)
      assert(router.nil?)
    end
  end

  def test_find_all
    assert_nothing_raised do
      # Get filters
      filters = Nanoc::PluginManager.instance.find_all(Nanoc::Filter)

      # Check
      assert(!filters.nil?)
      assert(filters.include?(Nanoc::Filters::ERB))
      assert(!filters.include?(Nanoc::DataSources::Filesystem))
      assert(!filters.include?(Nanoc::Routers::Default))
    end
  end

end
