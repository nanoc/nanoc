# encoding: utf-8

class Nanoc::Extra::Checking::Checkers::CSSTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run_ok
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h1>')
      File.write('output/style.css', 'h1 { color: red; }')

      # Run checker
      checker = Nanoc::Extra::Checking::Checkers::CSS.new(site)
      checker.run

      # Check
      assert checker.issues.empty?
    end
  end

  def test_run_error
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.write('output/blah.html', '<h1>Hi!</h1>')
      File.write('output/style.css', 'h1 { coxlor: rxed; }')

      # Run checker
      checker = Nanoc::Extra::Checking::Checkers::CSS.new(site)
      checker.run

      # Check
      refute checker.issues.empty?
    end
  end

end

