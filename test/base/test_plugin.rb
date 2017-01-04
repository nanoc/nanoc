require 'helper'

class Nanoc::PluginTest < Nanoc::TestCase
  class SamplePlugin
    extend Nanoc::Int::PluginRegistry::PluginMethods
  end

  class SampleFilter < SamplePlugin
    identifier :_plugin_test_sample_filter
  end

  def test_named
    # Find existant filter
    filter = SamplePlugin.named(:_plugin_test_sample_filter)
    assert(!filter.nil?)

    # Find non-existant filter
    filter = SamplePlugin.named(:lksdaffhdlkashlgkskahf)
    assert(filter.nil?)
  end

  def test_register
    SampleFilter.send(:identifier, :_plugin_test_sample_filter2)

    registry = Nanoc::Int::PluginRegistry.instance
    filter = registry.find(SamplePlugin, :_plugin_test_sample_filter2)

    refute_nil filter
  end
end
