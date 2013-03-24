# encoding: utf-8

class Nanoc::Extra::Watcher::RecompilerTest < Nanoc::TestCase

  class FakeUserNotifier

    attr_reader :messages

    def initialize
      @messages = []
    end

    def notify(message)
      @messages << message
    end

  end

  def test_notify_success
    with_site do
      config = {}
      user_notifier = FakeUserNotifier.new

      recompiler = Nanoc::Extra::Watcher::Recompiler.new(config, :user_notifier => user_notifier)
      File.open('Rules', 'w') { |io| io.write 'This is not really Ruby code' }
      recompiler.recompile

      assert_equal [ 'Compilation failed' ], user_notifier.messages
    end
  end

  def test_notify_failure
    with_site do
      config = {}
      user_notifier = FakeUserNotifier.new

      recompiler = Nanoc::Extra::Watcher::Recompiler.new(config, :user_notifier => user_notifier)
      recompiler.recompile

      assert_equal [ 'Compilation complete' ], user_notifier.messages
    end
  end

end
