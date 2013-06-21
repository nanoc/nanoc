# encoding: utf-8

class Nanoc::Extra::Checking::Checks::StaleTest < Nanoc::TestCase

  def check_class
    Nanoc::Extra::Checking::Checks::Stale
  end

  def calc_issues
    site = Nanoc::SiteLoader.new.load
    site.compiler.build_reps
    check = check_class.new(site)
    check.run
    check.issues
  end

  def test_run_ok
    with_site do |site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      # Empty
      FileUtils.mkdir_p('output')
      assert self.calc_issues.empty?

      # One OK file
      File.write('content/index.html', 'stuff')
      File.write('output/index.html', 'stuff')
      assert self.calc_issues.empty?
    end
  end

  def test_run_error
    with_site do |site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.write('content/index.html', 'stuff')
      File.write('output/WRONG.html', 'stuff')
      assert_equal 1, self.calc_issues.count
      issue = self.calc_issues.to_a[0]
      assert_equal "file without matching item", issue.description
      assert_equal "output/WRONG.html", issue.subject
    end
  end

  def test_run_excluded
    with_site do |site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.open('nanoc.yaml', 'w') { |io| io.write "prune:\n  exclude: [ 'excluded.html' ]" }
      File.write('content/index.html', 'stuff')
      File.write('output/excluded.html', 'stuff')
      assert self.calc_issues.empty?
    end
  end

  def test_run_excluded_with_broken_config
    with_site do |site|
      assert Dir['content/*'].empty?
      assert Dir['output/*'].empty?

      File.open('nanoc.yaml', 'w') { |io| io.write "prune:\n  blah: meh" }
      File.write('content/index.html', 'stuff')
      File.write('output/excluded.html', 'stuff')
      refute self.calc_issues.empty?
    end
  end

end
