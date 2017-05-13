# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::Checks::CSSTest < Nanoc::TestCase
  def test_run_ok
    VCR.use_cassette('css_run_ok') do
      with_site do |site|
        # Create files
        FileUtils.mkdir_p('output')
        File.open('output/blah.html', 'w') { |io| io.write('<h1>Hi!</h1>') }
        File.open('output/style.css', 'w') { |io| io.write('h1 { color: red; }') }

        # Run check
        check = Nanoc::Checking::Checks::CSS.create(site)
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
        check = Nanoc::Checking::Checks::CSS.create(site)
        check.run

        # Check
        refute check.issues.empty?
        assert_equal 1, check.issues.size
        assert_equal(
          'line 1: Property coxlor doesn\'t exist: h1 { coxlor: rxed; }',
          check.issues.to_a[0].description,
        )
      end
    end
  end

  def test_run_parse_error
    VCR.use_cassette('css_run_parse_error') do
      with_site do |site|
        # Create files
        FileUtils.mkdir_p('output')
        File.open('output/blah.html', 'w') { |io| io.write('<h1>Hi!</h1>') }
        File.open('output/style.css', 'w') { |io| io.write('h1 { ; {') }

        # Run check
        check = Nanoc::Checking::Checks::CSS.create(site)
        check.run

        # Check
        refute check.issues.empty?
        assert_equal 1, check.issues.size
        assert_equal 'line 1: Parse Error: h1 { ; {', check.issues.to_a[0].description
      end
    end
  end
end
