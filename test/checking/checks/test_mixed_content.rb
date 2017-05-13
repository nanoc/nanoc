# frozen_string_literal: true

require 'helper'

class Nanoc::Checking::Checks::MixedContentTest < Nanoc::TestCase
  def create_output_file(name, lines)
    FileUtils.mkdir_p('output')
    File.open('output/' + name, 'w') do |io|
      io.write(lines.join('\n'))
    end
  end

  def assert_include(haystack, needle)
    assert haystack.include?(needle), "Expected to find '#{needle}' in #{haystack}"
  end

  def test_https_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="https://nanoc.ws/logo.png" />',
        '<img src="HTTPS://nanoc.ws/logo.png" />',
        '<link href="https://nanoc.ws/style.css" />',
        '<script src="https://nanoc.ws/app.js"></script>',
        '<form action="https://nanoc.ws/process.cgi"></form>',
        '<iframe src="https://nanoc.ws/preview.html"></iframe>',
        '<audio src="https://nanoc.ws/theme-song.flac"></audio>',
        '<video src="https://nanoc.ws/screen-cast.mkv"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end

  def test_root_relative_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="/logo.png" />',
        '<link href="/style.css" />',
        '<script src="/app.js"></script>',
        '<form action="/process.cgi"></form>',
        '<iframe src="/preview.html"></iframe>',
        '<audio src="/theme-song.flac"></audio>',
        '<video src="/screen-cast.mkv"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end

  def test_protocol_relative_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="//nanoc.ws/logo.png" />',
        '<link href="//nanoc.ws/style.css" />',
        '<script src="//nanoc.ws/app.js"></script>',
        '<form action="//nanoc.ws/process.cgi"></form>',
        '<iframe src="//nanoc.ws/preview.html"></iframe>',
        '<audio src="//nanoc.ws/theme-song.flac"></audio>',
        '<video src="//nanoc.ws/screen-cast.mkv"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end

  def test_document_relative_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="logo.png" />',
        '<link href="style.css" />',
        '<script src="app.js"></script>',
        '<form action="process.cgi"></form>',
        '<iframe src="preview.html"></iframe>',
        '<audio src="theme-song.flac"></audio>',
        '<video src="screen-cast.mkv"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end

  def test_query_relative_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="?query-string" />',
        '<link href="?query-string" />',
        '<script src="?query-string"></script>',
        '<form action="?query-string"></form>',
        '<iframe src="?query-string"></iframe>',
        '<audio src="?query-string"></audio>',
        '<video src="?query-string"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end

  def test_fragment_relative_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="#fragment" />',
        '<link href="#fragment" />',
        '<script src="#fragment"></script>',
        '<form action="#fragment"></form>',
        '<iframe src="#fragment"></iframe>',
        '<audio src="#fragment"></audio>',
        '<video src="#fragment"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end

  def test_http_content
    with_site do |site|
      create_output_file('foo.html', [
        '<img src="http://nanoc.ws/logo.png" />',
        '<img src="HTTP://nanoc.ws/logo.png" />',
        '<link href="http://nanoc.ws/style.css" />',
        '<script src="http://nanoc.ws/app.js"></script>',
        '<form action="http://nanoc.ws/process.cgi"></form>',
        '<iframe src="http://nanoc.ws/preview.html"></iframe>',
        '<audio src="http://nanoc.ws/theme-song.flac"></audio>',
        '<video src="http://nanoc.ws/screencast.mkv"></video>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      issues = check.issues.to_a
      assert_equal 8, issues.count

      descriptions = issues.map(&:description)
      issues.each do |issue|
        assert_equal 'output/foo.html', issue.subject
      end

      # The order of the reported issues is not important, so use this class's
      # `assert_include` helper to avoid asserting those details
      assert_include descriptions, 'mixed content include: http://nanoc.ws/logo.png'

      assert_include descriptions, 'mixed content include: HTTP://nanoc.ws/logo.png'

      assert_include descriptions, 'mixed content include: http://nanoc.ws/style.css'

      assert_include descriptions, 'mixed content include: http://nanoc.ws/app.js'

      assert_include descriptions, 'mixed content include: http://nanoc.ws/process.cgi'

      assert_include descriptions, 'mixed content include: http://nanoc.ws/preview.html'

      assert_include descriptions, 'mixed content include: http://nanoc.ws/theme-song.flac'

      assert_include descriptions, 'mixed content include: http://nanoc.ws/screencast.mkv'
    end
  end

  def test_inert_content
    with_site do |site|
      create_output_file('foo.html', [
        '<a href="http://nanoc.ws">The homepage</a>',
        '<a name="Not a link">Content</a>',
        '<script>// inline JavaScript</script>',
        '<img href="http://nanoc.ws/logo.png" />',
        '<link src="http://nanoc.ws/style.css" />',
        '<script href="http://nanoc.ws/app.js"></script>',
        '<form src="http://nanoc.ws/process.cgi"></form>',
        '<iframe href="http://nanoc.ws/preview.html"></iframe>',
        '<audio href="http://nanoc.ws/theme-song.flac"></audio>',
        '<video target="http://nanoc.ws/screen-cast.mkv"></video>',
        '<p>http://nanoc.ws/harmless-text</p>',
      ])
      check = Nanoc::Checking::Checks::MixedContent.create(site)
      check.run

      assert_empty check.issues
    end
  end
end
