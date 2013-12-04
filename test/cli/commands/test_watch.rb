# encoding: utf-8

class Nanoc::CLI::Commands::WatchTest < Nanoc::TestCase

  def test_run
    with_site do |s|
      watch_thread = Thread.new do
        Nanoc::CLI.run %w( watch )
      end

      File.open('content/index.html', 'w') { |io| io.write('Hello there!') }
      self.wait_until_content_equals('content/index.html', 'Hello there!')

      File.open('content/index.html', 'w') { |io| io.write('Hello there again!') }
      self.wait_until_content_equals('content/index.html', 'Hello there again!')

      watch_thread.kill
    end
  end

  def test_notify
    with_site do |s|
      watch_thread = Thread.new do
        Nanoc::CLI.run %w( watch )
      end

      File.open('content/index.html', 'w') { |io| io.write('Hello there!') }
      self.wait_until_exists('output/index.html')
      assert_equal 'Hello there!', File.read('output/index.html')

      watch_thread.kill
    end
  end

  def test_growlnotify_cmd
    Nanoc::CLI.setup
    notifier = Nanoc::CLI::Commands::Watch::Notifier.new
    assert_equal [ 'growlnotify', '-m', 'foo' ], notifier.send(:growlnotify_cmd_for, 'foo')
  end

  def test_growlnotify_windows_cmd
    Nanoc::CLI.setup
    notifier = Nanoc::CLI::Commands::Watch::Notifier.new
    assert_equal [ 'growlnotify', '/t:nanoc', 'foo' ], notifier.send(:growlnotify_windows_cmd_for, 'foo')
  end

  def wait_until_exists(filename)
    20.times do
      break if File.file?(filename)
      sleep 0.5
    end
    if !File.file?(filename)
      raise RuntimeError, "Expected #{filename} to appear but it didn't :("
    end
  end

  def wait_until_content_equals(filename, expected_content)
    self.wait_until_exists(filename)

    20.times do
      break if File.read(filename) == expected_content
      sleep 0.5
    end

    actual_content = File.read(filename)
    if actual_content != expected_content
      raise RuntimeError, "Expected #{filename} to have " \
        "content #{expected_content.inspect} but it had " \
        "content #{actual_content.inspect} instead :("
    end

    # Ugly, but seems to be necessary or changes are not picked up. :(
    sleep 0.5
  end

end
