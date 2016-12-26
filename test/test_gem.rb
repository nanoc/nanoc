require 'helper'

class Nanoc::GemTest < Nanoc::TestCase
  def setup
    super
    FileUtils.cd(@orig_wd)
  end

  def test_build
    # Require clean environment
    Dir['nanoc-*.gem'].each { |f| FileUtils.rm(f) }

    # Build
    files_before = Set.new Dir['**/*']
    stdout = StringIO.new
    stderr = StringIO.new
    piper = Nanoc::Extra::Piper.new(stdout: stdout, stderr: stderr)

    begin
      piper.run(%w(gem build nanoc.gemspec), nil)
    rescue => e
      STDOUT.puts "Error!"
      STDOUT.puts "stdout: #{stdout.string.inspect}"
      STDOUT.puts "stderr: #{stderr.string.inspect}"
      raise e
    end
    files_after = Set.new Dir['**/*']

    # Check new files
    diff = files_after - files_before
    assert_equal 1, diff.size
    assert_match(/^nanoc-.*\.gem$/, diff.to_a[0])
  ensure
    Dir['nanoc-*.gem'].each { |f| FileUtils.rm(f) }
  end
end
