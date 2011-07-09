# encoding: utf-8

class Nanoc3::CommandTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_resolution_for_with_unknown_gem
    error = LoadError.new('no such file to load -- afjlrestjlsgrshter')
    assert_nil cmd.send(:resolution_for, error)
  end

  def test_resolution_for_with_known_gem
    $loud = true
    error = LoadError.new('no such file to load -- kramdown')
    assert_match /^Try installing /, cmd.send(:resolution_for, error)
  ensure
    $loud = false
  end

  def test_resolution_for_with_not_load_error
    error = RuntimeError.new('nuclear meltdown detected')
    assert_nil cmd.send(:resolution_for, error)
  end

  def cmd
    Nanoc3::CLI::Command.new([], [], nil)
  end

end
