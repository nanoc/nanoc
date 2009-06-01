# encoding: utf-8

require 'test/helper'

class Nanoc3::PluginTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_named
    # Find existant filter
    filter = Nanoc3::Filter.named(:erb)
    assert(!filter.nil?)

    # Find non-existant filter
    filter = Nanoc3::Filter.named(:lksdaffhdlkashlgkskahf)
    assert(filter.nil?)
  end

end
