# encoding: utf-8

require 'tempfile'

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
    stderr = ""
    piper = Nanoc::Extra::Piper.new(:stdout => stdout)
    Tempfile.open('stderr') do |temp_file|
      piper.run(["gem build nanoc.gemspec 2>#{temp_file.path.inspect}"], nil)
      stderr = File.open(temp_file.path){|file| file.readlines }
    end
    files_after = Set.new Dir['**/*']

    # Check new files
    diff = files_after - files_before
    assert_equal 1, diff.size
    assert_match(/^nanoc-.*\.gem$/, diff.to_a[0])

    # Check output
    assert_match(/Successfully built RubyGem\s+Name: nanoc\s+Version: .*\s+File: nanoc-.*\.gem\s+/, stdout.string)
    assert_equal [], stderr
  ensure
    Dir['nanoc-*.gem'].each { |f| FileUtils.rm(f) }
  end
end
