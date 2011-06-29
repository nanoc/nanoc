# encoding: utf-8

class Nanoc::PluginTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  class SampleFilter < Nanoc::Filter
    identifier :_plugin_test_sample_filter
  end

  def test_named
    # Find existant filter
    filter = Nanoc::Filter.named(:erb)
    assert(!filter.nil?)

    # Find non-existant filter
    filter = Nanoc::Filter.named(:lksdaffhdlkashlgkskahf)
    assert(filter.nil?)
  end

  def test_register
    SampleFilter.send(:identifier, :_plugin_test_sample_filter)

    registry = Nanoc::PluginRegistry.instance
    filter = registry.find(Nanoc::Filter, :_plugin_test_sample_filter)

    refute_nil filter
  end

end
