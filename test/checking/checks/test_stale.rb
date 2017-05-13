# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::Checks::StaleTest < Nanoc::TestCase
  def check_class
    Nanoc::Checking::Checks::Stale
  end

  def calc_issues
    site = Nanoc::Int::SiteLoader.new.new_from_cwd
    runner = Nanoc::Checking::Runner.new(site)
    runner.run_checks([check_class])
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

      File.open('nanoc.yaml', 'w') { |io| io.write "string_pattern_type: legacy\nprune:\n  exclude: [ 'excluded.html' ]" }
      File.open('content/index.html', 'w') { |io| io.write('stuff') }
      File.open('output/excluded.html', 'w') { |io| io.write('stuff') }
      assert calc_issues.empty?
    end
  end

  def test_run_excluded_with_broken_config
    with_site do |_site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.open('nanoc.yaml', 'w') { |io| io.write "string_pattern_type: legacy\nprune:\n  blah: meh" }
      File.open('content/index.html', 'w') { |io| io.write('stuff') }
      File.open('output/excluded.html', 'w') { |io| io.write('stuff') }
      refute calc_issues.empty?
    end
  end
end
