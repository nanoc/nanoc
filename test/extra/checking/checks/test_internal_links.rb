# encoding: utf-8

class Nanoc::Extra::Checking::Checks::InternalLinksTest < Nanoc::TestCase

  def test_run
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/foo.txt',  'w') { |io| io.write('<a href="/broken">broken</a>') }
      File.open('output/bar.html', 'w') { |io| io.write('<a href="/foo.txt">not broken</a>') }

      # Create check
      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)
      check.run

      # Test
      assert check.issues.empty?
    end
  end

  def test_valid?
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/origin',     'w') { |io| io.write('hi') }
      File.open('output/foo',        'w') { |io| io.write('hi') }
      File.open('output/stuff/blah', 'w') { |io| io.write('hi') }

      # Create check
      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)

      # Test
      assert check.send(:valid?, 'foo',         'output/origin')
      assert check.send(:valid?, 'origin',      'output/origin')
      assert check.send(:valid?, 'stuff/blah',  'output/origin')
      assert check.send(:valid?, '/foo',        'output/origin')
      assert check.send(:valid?, '/origin',     'output/origin')
      assert check.send(:valid?, '/stuff/blah', 'output/origin')
    end
  end

  def test_remove_query_string
    with_site do |site|
      FileUtils.mkdir_p('output/stuff')
      File.open('output/stuff/right', 'w') { |io| io.write('hi') }

      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)

      assert check.send(:valid?, 'stuff/right?foo=123', 'output/origin')
      refute check.send(:valid?, 'stuff/wrong?foo=123', 'output/origin')
    end
  end

  def test_exclude
    with_site do |site|
      # Create check
      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)
      site.config.update({ :checks => { :internal_links => { :exclude => ['^/excluded\d+'] } } })

      # Test
      assert check.send(:valid?, '/excluded1', 'output/origin')
      assert check.send(:valid?, '/excluded2', 'output/origin')
      assert !check.send(:valid?, '/excluded_not', 'output/origin')
    end
  end

  def test_unescape_url
    with_site do |site|
      FileUtils.mkdir_p('output/stuff')
      File.open('output/stuff/right foo', 'w') { |io| io.write('hi') }

      check = Nanoc::Extra::Checking::Checks::InternalLinks.new(site)

      assert check.send(:valid?, 'stuff/right%20foo', 'output/origin')
      refute check.send(:valid?, 'stuff/wrong%20foo', 'output/origin')
    end
  end

end
