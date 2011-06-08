# encoding: utf-8

class Nanoc3::PluginTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class SampleFilter < Nanoc3::Filter
    identifier :_plugin_test_sample_filter
  end

  def test_named
    # Find existant filter
    filter = Nanoc3::Filter.named(:erb)
    assert(!filter.nil?)

    # Find non-existant filter
    filter = Nanoc3::Filter.named(:lksdaffhdlkashlgkskahf)
    assert(filter.nil?)
  end

  def test_register
    SampleFilter.send(:identifier, :_plugin_test_sample_filter)

    registry = Nanoc3::PluginRegistry.instance
    filter = registry.find(Nanoc3::Filter, :_plugin_test_sample_filter)

    refute_nil filter
  end

end
