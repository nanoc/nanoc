# encoding: utf-8

class Nanoc::GemTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def setup
    super
    FileUtils.cd(@orig_wd)
  end

  def test_build
    require 'systemu'

    # Require clean environment
    assert_empty Dir['nanoc-*.gem'], "Ensure no nanoc-*.gem files exist"

    # Build
    files_before = Set.new Dir['**/*']
    stdout = ''
    stderr = ''
    status = systemu(
      [ 'gem', 'build', 'nanoc.gemspec' ],
      'stdin'  => '',
      'stdout' => stdout,
      'stderr' => stderr)
    assert status.success?
    files_after = Set.new Dir['**/*']

    # Check new files
    diff = files_after - files_before
    assert_equal 1, diff.size
    assert_match(/^nanoc-.*\.gem$/, diff.to_a[0])

    # Check output
    assert_match(/Successfully built RubyGem\n  Name: nanoc\n  Version: .*\n  File: nanoc-.*\.gem\n/, stdout)
    assert_equal '', stderr
  ensure
    Dir['nanoc-*.gem'].each { |f| FileUtils.rm(f) }
  end

end
