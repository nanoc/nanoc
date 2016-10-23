class Nanoc::Extra::Checking::Checks::HTMLTest < Nanoc::TestCase
  def test_run_ok
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<!DOCTYPE html><html><head><meta charset="utf-8"><title>Hello</title></head><body><h1>Hi!</h1></body>') }
      File.open('output/style.css', 'w') { |io| io.write('h1 { coxlor: rxed; }') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::HTML.create(site)
      check.run

      # Check
      assert_empty check.issues
    end
  end

  def test_run_error_unexpected_end_tag
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<h2>Hi!</h1>') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::HTML.create(site)
      check.run

      # Check
      assert_equal 1, check.issues.size
      assert_equal 'Unexpected end tag : h1 (line 1, column 13)', check.issues.to_a[0].description
    end
  end

  def test_run_error_invalid_tag
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<donkey>Hi!</donkey>') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::HTML.create(site)
      check.run

      # Check
      assert_equal 1, check.issues.size
      assert_equal 'Tag donkey invalid (line 1, column 8)', check.issues.to_a[0].description
    end
  end

  def test_run_error_valid_html5_tag
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<output>Hi!</output>') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::HTML.create(site)
      check.run

      # Check
      assert_empty check.issues
    end
  end

  def test_run_error_valid_svg_tag
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/blah.html', 'w') { |io| io.write('<feMergeNode>whatever</feMergeNode>') }

      # Run check
      check = Nanoc::Extra::Checking::Checks::HTML.create(site)
      check.run

      # Check
      assert_empty check.issues
    end
  end
end
