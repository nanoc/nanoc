require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class PluginManagerTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_data_source_named_right
    # Symbol
    assert_nothing_raised do
      data_source = Nanoc::PluginManager.data_source_named(:filesystem)
      assert(!data_source.nil?)
    end

    # String
    assert_nothing_raised do
      data_source = Nanoc::PluginManager.data_source_named('filesystem')
      assert(!data_source.nil?)
    end
  end

  def test_data_source_named_wrong
    # Symbol
    assert_nothing_raised do
      data_source = Nanoc::PluginManager.data_source_named(:lksdaffhdlkashlgkskahf)
      assert(data_source.nil?)
    end

    # String
    assert_nothing_raised do
      data_source = Nanoc::PluginManager.data_source_named('lksdaffhdlkashlgkskahf')
      assert(data_source.nil?)
    end
  end

  def test_filter_named_right
    # Symbol
    assert_nothing_raised do
      filter = Nanoc::PluginManager.filter_named(:erb)
      assert(!filter.nil?)
    end

    # String
    assert_nothing_raised do
      filter = Nanoc::PluginManager.filter_named('erb')
      assert(!filter.nil?)
    end
  end

  def test_filter_named_wrong
    # Symbol
    assert_nothing_raised do
      filter = Nanoc::PluginManager.filter_named(:lksdaffhdlkashlgkskahf)
      assert(filter.nil?)
    end

    # String
    assert_nothing_raised do
      filter = Nanoc::PluginManager.filter_named('lksdaffhdlkashlgkskahf')
      assert(filter.nil?)
    end
  end

  def test_layout_processor_for_extension_right
    # Symbol
    assert_nothing_raised do
      layout_processor = Nanoc::PluginManager.layout_processor_for_extension(:'.erb')
      assert(!layout_processor.nil?)
    end

    # String
    assert_nothing_raised do
      layout_processor = Nanoc::PluginManager.layout_processor_for_extension('.erb')
      assert(!layout_processor.nil?)
    end
  end

  def test_layout_processor_for_extension_wrong
    # Symbol
    assert_nothing_raised do
      layout_processor = Nanoc::PluginManager.layout_processor_for_extension(:'.xxx')
      assert(layout_processor.nil?)
    end

    # String
    assert_nothing_raised do
      layout_processor = Nanoc::PluginManager.layout_processor_for_extension('.xxx')
      assert(layout_processor.nil?)
    end
  end

end
