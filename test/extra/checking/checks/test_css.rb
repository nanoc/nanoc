# encoding: utf-8

class Nanoc::Extra::Checking::Checks::CSSTest < Nanoc::TestCase

  def test_run_ok
    VCR.use_cassette('css_run_ok') do
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
  end

  def test_run_error
    VCR.use_cassette('css_run_error') do
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

end

