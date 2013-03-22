# encoding: utf-8

class Nanoc::Extra::WatcherTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def setup
    super
    @num = 0
    @changed = false
  end

  def modify(filename)
    File.open(filename, 'w') { |io| io.write(@num.to_s) }
    @num += 1
  end

  def wait_for_change
    20.times do
      break if @changed
      sleep 0.1
    end
    if !@changed
      raise RuntimeError, "Expected change"
    end
    @changed = false
  end

  def run_detector_while
    detector = Nanoc::Extra::Watcher::ChangeDetector.new
    detector.on_change { @changed = true }

    begin
      Thread.new { detector.run }
      sleep 0.1 # needed to let the listener catch up

      yield
    ensure
      detector.stop
    end
  end

  def test_detect_changes
    with_site do
      run_detector_while do
        modify('Rules')
        wait_for_change

        modify('Rules.rb')
        wait_for_change

        modify('rules')
        wait_for_change

        modify('Rules.rb')
        wait_for_change

        modify('config.yaml')
        wait_for_change

        modify('nanoc.yaml')
        wait_for_change
      end
    end
  end

end
