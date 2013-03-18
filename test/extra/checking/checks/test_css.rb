# encoding: utf-8

class Nanoc::Extra::Checking::Checks::CSSTest < Nanoc::TestCase

  def test_run_ok
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<h1>Hi!</h1>') }
      File.open('output/style.css', 'w') { |io| io.write('h1 { color: red; }') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::CSS.new(site)
      check.run

      # Check
      assert check.issues.empty?
    end
  end

  def test_run_error
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<h1>Hi!</h1>') }
      File.open('output/style.css', 'w') { |io| io.write('h1 { coxlor: rxed; }') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::CSS.new(site)
      check.run

      # Check
      refute check.issues.empty?
    end
  end

end

