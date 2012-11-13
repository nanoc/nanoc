# encoding: utf-8

class Nanoc::CLI::Commands::WatchTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

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
    old_path = ENV['PATH']
    with_site do |s|
      watch_thread = Thread.new do
        Nanoc::CLI.run %w( watch )
      end

      ENV['PATH'] = '.' # so that neither which nor where can be found
      File.open('content/index.html', 'w') { |io| io.write('Hello there!') }
      self.wait_until_exists('output/index.html')
      assert_equal 'Hello there!', File.read('output/index.html')

      watch_thread.kill
    end
  ensure
    ENV['PATH'] = old_path
  end

  def wait_until_exists(filename)
    10.times do
      break if File.file?(filename)
      sleep 0.5
    end
    if !File.file?(filename)
      raise RuntimeError, "Expected #{filename} to appear but it didn't :("
    end
  end

  def wait_until_content_equals(filename, content)
    self.wait_until_exists(filename)

    10.times do
      break if File.read(filename) == content
      sleep 0.5
    end
    if File.read(filename) != content
      raise RuntimeError, "Expected #{filename} to have content #{content} but it doesn't :("
    end
  end

end
