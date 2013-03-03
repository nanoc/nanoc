# encoding: utf-8

class Nanoc::Extra::UserNotifierTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_notify
    # TODO implement

    notifier = Nanoc::Extra::UserNotifier.new
    notifier.notify("nanoc test notification")
  end

  def test_find_tool
    # TODO implement
  end

  def test_on_windows
    # FIXME this test is icky

    notifier = Nanoc::Extra::UserNotifier.new
    if RUBY_PLATFORM =~ /mingw|mswin/
      assert notifier.on_windows?
    else
      refute notifier.on_windows?
    end
  end

  def test_find_binary_command
    notifier = Nanoc::Extra::UserNotifier.new
    notifier.pretend_not_on_windows
    assert_equal 'which', notifier.find_binary_command

    notifier = Nanoc::Extra::UserNotifier.new
    notifier.pretend_on_windows
    assert_equal 'where', notifier.find_binary_command
  end

end
