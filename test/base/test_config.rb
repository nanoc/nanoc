# encoding: utf-8

require 'test/helper'

class Nanoc3::ConfigTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_initialize_with_mtime
    # Mock time
    time = Time.now - 800

    # Create config
    config = Nanoc3::Config.new({ :foo => 'bar' }, time)

    # Test merge
    assert_equal 'bar',    config[:foo]
    assert_equal 'output', config[:output_dir]

    # Test mtime
    assert_equal time, config.mtime
  end

  def test_initialize_without_mtime
    # Create config
    config = Nanoc3::Config.new({ :foo => 'bar' })

    # Test mtime
    assert_equal nil, config.mtime
  end

end
