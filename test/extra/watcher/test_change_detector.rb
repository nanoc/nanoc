# encoding: utf-8

class Nanoc::Extra::Watcher::ChangeDetectorTest < Nanoc::TestCase

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
    res = @changed
    @changed = false
    res
  end

  def assert_change_detected
    res = wait_for_change
    raise "Change expected" unless res
  end

  def refute_change_detected
    res = wait_for_change
    raise "No change expected" if res
  end

  def run_detector_while
    detector = Nanoc::Extra::Watcher::ChangeDetector.new
    detector.on_change { @changed = true }
    detector.start
    sleep 0.5 # needed to let the listener catch up
    begin
      yield
    ensure
      detector.stop
    end
  end

  def test_detect_changes_to_rules
    with_site do
      run_detector_while do
        modify('Rules')
        assert_change_detected

        modify('Rules.rb')
        assert_change_detected

        modify('rules')
        assert_change_detected

        modify('Rules.rb')
        assert_change_detected
      end
    end
  end

  def test_detect_changes_to_config
    with_site do
      run_detector_while do
        modify('config.yaml')
        assert_change_detected

        modify('nanoc.yaml')
        assert_change_detected
      end
    end
  end

  def test_detect_changes_to_content
    with_site do
      run_detector_while do
        modify('content/meh.md')
        assert_change_detected
      end
    end
  end

  def test_detect_changes_to_layout
    with_site do
      run_detector_while do
        modify('layouts/article.erb')
        assert_change_detected
      end
    end
  end

  def test_detect_no_changes_to_output
    with_site do
      run_detector_while do
        modify('output/meh.html')
        refute_change_detected
      end
    end
  end

  def test_detect_no_changes_to_tmp
    with_site do
      run_detector_while do
        FileUtils.mkdir_p('tmp')
        modify('tmp/bleh.db')
        refute_change_detected
      end
    end
  end

  def test_detect_additions
    with_site do
      run_detector_while do
        modify('content/new.md')
        assert_change_detected
      end
    end
  end

  def test_detect_changes
    with_site do
      File.open('content/index.html', 'w') { |io| io.write('bleh') }
      run_detector_while do
        modify('content/index.html')
        assert_change_detected
      end
    end
  end

  def test_detect_removals
    with_site do
      File.open('content/index.html', 'w') { |io| io.write('bleh') }
      run_detector_while do
        FileUtils.rm('content/index.html')
        assert_change_detected
      end
    end
  end

end
