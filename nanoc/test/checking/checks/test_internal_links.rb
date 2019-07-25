# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::Checks::InternalLinksTest < Nanoc::TestCase
  def test_no_issues
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/foo.xhtml', 'w') { |io| io.write('<a href="/bar.html">not broken</a>') }
      File.open('output/bar.html', 'w') { |io| io.write('<a href="/foo.xhtml">not broken</a>') }

      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      check.run

      # Test
      assert check.issues.empty?
    end
  end

  def test_has_issues
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/foo.html', 'w') { |io| io.write('<a href="/broken">broken</a>') }

      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      check.run

      # Test
      refute check.issues.empty?
    end
  end

  def test_resource_uris
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      File.open('output/bar.html', 'w') { |io| io.write('<link rel="stylesheet" href="/styledinges.css">') }

      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      check.run

      # Test
      assert check.issues.size == 1
    end
  end

  def test_valid?
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output/stuff')
      File.open('output/origin',     'w') { |io| io.write('hi') }
      File.open('output/foo',        'w') { |io| io.write('hi') }
      File.open('output/stuff/blah', 'w') { |io| io.write('hi') }

      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      # Test
      assert check.send(:valid?, path_to_file_uri('foo', site),         'output/origin')
      assert check.send(:valid?, path_to_file_uri('origin', site),      'output/origin')
      assert check.send(:valid?, path_to_file_uri('stuff/blah', site),  'output/origin')
      assert check.send(:valid?, path_to_file_uri('/foo', site),        'output/origin')
      assert check.send(:valid?, path_to_file_uri('/origin', site),     'output/origin')
      assert check.send(:valid?, path_to_file_uri('/stuff/blah', site), 'output/origin')
    end
  end

  def test_remove_query_string
    with_site do |site|
      FileUtils.mkdir_p('output/stuff')
      File.open('output/stuff/right', 'w') { |io| io.write('hi') }

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, '/stuff/right?foo=123', 'output/origin')
      assert check.send(:valid?, 'stuff/right?foo=456', 'output/origin')
      refute check.send(:valid?, 'stuff/wrong?foo=123', 'output/origin')
    end
  end

  def test_exclude
    with_site do |site|
      site.config.update(checks: { internal_links: { exclude: ['^/excluded\d+'] } })

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, path_to_file_uri('/excluded1', site), 'output/origin')
      assert check.send(:valid?, path_to_file_uri('/excluded2', site), 'output/origin')
      refute check.send(:valid?, path_to_file_uri('/excluded_not', site), 'output/origin')
    end
  end

  def test_exclude_targets
    with_site do |site|
      site.config.update(checks: { internal_links: { exclude_targets: ['^/excluded\d+'] } })

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, path_to_file_uri('/excluded1', site), 'output/origin')
      assert check.send(:valid?, path_to_file_uri('/excluded2/two', site), 'output/origin')
      assert !check.send(:valid?, path_to_file_uri('/excluded_not', site), 'output/origin')
    end
  end

  def test_exclude_origins
    with_site do |site|
      site.config.update(checks: { internal_links: { exclude_origins: ['^/excluded'] } })

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, path_to_file_uri('/foo', site), 'output/excluded')
      assert !check.send(:valid?, path_to_file_uri('/foo', site), 'output/not_excluded')
    end
  end

  def test_unescape_url
    with_site do |site|
      FileUtils.mkdir_p('output/stuff')
      File.open('output/stuff/right foo', 'w') { |io| io.write('hi') }

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, path_to_file_uri('stuff/right%20foo', site), 'output/origin')
      refute check.send(:valid?, path_to_file_uri('stuff/wrong%20foo', site), 'output/origin')
    end
  end

  def test_deeply_nesten_relative_paths
    with_site do |site|
      FileUtils.mkdir_p('output/one/two/three')
      File.open('output/one/two/three/a.html', 'w') { |io| io.write('<a href="../../b.html">b</a>') }
      File.open('output/one/b.html', 'w') { |io| io.write('<a href="two/three/a.html">a</a>') }
      File.open('output/one/c.html', 'w') { |io| io.write('<a href="../one/c.html">c</a>') }

      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      check.run

      assert check.issues.empty?
    end
  end

  def test_protocol_relative_url
    # Protocol-relative URLs are not internal links.

    with_site do |site|
      FileUtils.mkdir_p('output')
      File.write('output/a.html', '<a href="//example.com/broken">broken</a>')

      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      check.run

      assert check.issues.empty?
    end
  end
end
