# encoding: utf-8

class Nanoc::Extra::Checking::Checks::StaleTest < Nanoc::TestCase
  def check_class
    Nanoc::Extra::Checking::Checks::Stale
  end

  def calc_issues
    site = Nanoc::Int::Site.new('.')
    check = check_class.new(site)
    check.run
    check.issues
  end

  def test_run_ok
    with_site do |_site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      # Empty
      FileUtils.mkdir_p('output')
      assert calc_issues.empty?

      # One OK file
      File.open('content/index.html', 'w') { |io| io.write('stuff') }
      File.open('output/index.html', 'w') { |io| io.write('stuff') }
      assert calc_issues.empty?
    end
  end

  def test_run_error
    with_site do |_site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.open('content/index.html', 'w') { |io| io.write('stuff') }
      File.open('output/WRONG.html', 'w') { |io| io.write('stuff') }
      assert_equal 1, calc_issues.count
      issue = calc_issues.to_a[0]
      assert_equal 'file without matching item', issue.description
      assert_equal 'output/WRONG.html', issue.subject
    end
  end

  def test_run_excluded
    with_site do |_site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.open('nanoc.yaml', 'w') { |io| io.write "pattern_type: legacy\nprune:\n  exclude: [ 'excluded.html' ]" }
      File.open('content/index.html', 'w') { |io| io.write('stuff') }
      File.open('output/excluded.html', 'w') { |io| io.write('stuff') }
      assert calc_issues.empty?
    end
  end

  def test_run_excluded_with_broken_config
    with_site do |_site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.open('nanoc.yaml', 'w') { |io| io.write "pattern_type: legacy\nprune:\n  blah: meh" }
      File.open('content/index.html', 'w') { |io| io.write('stuff') }
      File.open('output/excluded.html', 'w') { |io| io.write('stuff') }
      refute calc_issues.empty?
    end
  end
end
