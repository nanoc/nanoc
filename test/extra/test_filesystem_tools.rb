# encoding: utf-8

class Nanoc::Extra::FilesystemToolsTest < Nanoc::TestCase

  def test_all_files_in_follows_symlinks_to_dirs
    # Write sample files
    (0..15).each do |i|
      FileUtils.mkdir_p("dir#{i}")
      File.open("dir#{i}/foo.md", 'w') { |io| io.write('o hai') }
    end
    (1..15).each do |i|
      File.symlink("dir#{i}", "dir#{i-1}/sub")
    end

    # Check
    # 11 expected files (follow symlink 10 times)
    # sort required because 10 comes before 2
    expected_files = (0..10).map { |i| "dir#{i}/foo.md" }.sort
    actual_files   = Nanoc::Extra::FilesystemTools.all_files_in('dir0').sort
    assert_equal expected_files, actual_files
  end

  def test_all_files_in_follows_symlinks_to_files
    # Write sample files
    File.open('bar', 'w') { |io| io.write('o hai from bar') }
    FileUtils.mkdir_p('dir')
    File.open('dir/foo', 'w') { |io| io.write('o hai from foo') }
    File.symlink('bar', 'dir/bar-link')

    # Check
    expected_files = [ 'bar', 'dir/foo' ]
    actual_files   = Nanoc::Extra::FilesystemTools.all_files_in('dir').sort
    assert_equal expected_files, actual_files
  end

end
