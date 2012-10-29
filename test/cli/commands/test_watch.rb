# encoding: utf-8

class Nanoc::CLI::Commands::WatchTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def setup
    super
    @warned ||= begin
      $stderr.puts "\n(fssm deprecation warning can be ignored; master branch uses guard/listen)"
      true
    end
  end

  def test_run
    require 'open-uri'
    with_site do |s|
      watch_thread = Thread.new do
        Nanoc::CLI.run %w( watch )
      end
      sleep 2

      File.open('content/index.html', 'w') { |io| io.write('Hello there!') }
      sleep 2
      assert_equal 'Hello there!', File.read('output/index.html')

      File.open('content/index.html', 'w') { |io| io.write('Hello there again!') }
      sleep 2
      assert_equal 'Hello there again!', File.read('output/index.html')

      watch_thread.kill
    end

  end

end
