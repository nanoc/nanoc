# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::Checks::InternalLinksTest < Nanoc::TestCase
  def test_run
    with_site do |site|
      # Create files
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/foo.txt',  'w') { |io| io.write('<a href="/broken">broken</a>') }
      File.open('output/bar.html', 'w') { |io| io.write('<a href="/foo.txt">not broken</a>') }

      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      check.run

      # Test
      assert check.issues.empty?
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
      FileUtils.mkdir_p('output')
      FileUtils.mkdir_p('output/stuff')
      File.open('output/origin',     'w') { |io| io.write('hi') }
      File.open('output/foo',        'w') { |io| io.write('hi') }
      File.open('output/stuff/blah', 'w') { |io| io.write('hi') }

      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)

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

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, 'stuff/right?foo=123', 'output/origin')
      refute check.send(:valid?, 'stuff/wrong?foo=123', 'output/origin')
    end
  end

  def test_exclude
    with_site do |site|
      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      site.config.update(checks: { internal_links: { exclude: ['^/excluded\d+'] } })

      # Test
      assert check.send(:valid?, '/excluded1', 'output/origin')
      assert check.send(:valid?, '/excluded2', 'output/origin')
      assert !check.send(:valid?, '/excluded_not', 'output/origin')
    end
  end

  def test_exclude_targets
    with_site do |site|
      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      site.config.update(checks: { internal_links: { exclude_targets: ['^/excluded\d+'] } })

      # Test
      assert check.send(:valid?, '/excluded1', 'output/origin')
      assert check.send(:valid?, '/excluded2', 'output/origin')
      assert !check.send(:valid?, '/excluded_not', 'output/origin')
    end
  end

  def test_exclude_origins
    with_site do |site|
      # Create check
      check = Nanoc::Checking::Checks::InternalLinks.create(site)
      site.config.update(checks: { internal_links: { exclude_origins: ['^/excluded'] } })

      # Test
      assert check.send(:valid?, '/foo', 'output/excluded')
      assert !check.send(:valid?, '/foo', 'output/not_excluded')
    end
  end

  def test_unescape_url
    with_site do |site|
      FileUtils.mkdir_p('output/stuff')
      File.open('output/stuff/right foo', 'w') { |io| io.write('hi') }

      check = Nanoc::Checking::Checks::InternalLinks.create(site)

      assert check.send(:valid?, 'stuff/right%20foo', 'output/origin')
      refute check.send(:valid?, 'stuff/wrong%20foo', 'output/origin')
    end
  end
end
