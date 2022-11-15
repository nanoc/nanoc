# frozen_string_literal: true

require 'helper'

class Nanoc::DataSources::FilesystemToolsTest < Nanoc::TestCase
  def setup
    super
    skip_unless_symlinks_supported
  end

  def test_all_files_in_follows_symlinks_to_dirs
    # Write sample files
    16.times do |i|
      FileUtils.mkdir_p("dir#{i}")
      File.write("dir#{i}/foo.md", 'o hai')
    end
    (1..10).each do |i|
      File.symlink("../dir#{i}", "dir#{i - 1}/sub")
    end

    # Check
    # 11 expected files (follow symlink 10 times)
    # sort required because 10 comes before 2
    expected_files = [
      'dir0/foo.md',
      'dir0/sub/foo.md',
      'dir0/sub/sub/foo.md',
      'dir0/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/sub/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/sub/sub/sub/sub/sub/foo.md',
      'dir0/sub/sub/sub/sub/sub/sub/sub/sub/sub/sub/foo.md',
    ]
    actual_files = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir0', nil).sort

    assert_equal expected_files, actual_files
  end

  def test_all_files_in_follows_symlinks_to_dirs_too_many
    # Write sample files
    16.times do |i|
      FileUtils.mkdir_p("dir#{i}")
      File.write("dir#{i}/foo.md", 'o hai')
    end
    (1..15).each do |i|
      File.symlink("../dir#{i}", "dir#{i - 1}/sub")
    end

    assert_raises Nanoc::DataSources::Filesystem::Tools::MaxSymlinkDepthExceededError do
      Nanoc::DataSources::Filesystem::Tools.all_files_in('dir0', nil)
    end
  end

  def test_all_files_in_relativizes_directory_names
    FileUtils.mkdir('foo')
    FileUtils.mkdir('bar')

    File.write('foo/x.md', 'o hai from foo/x')
    File.write('bar/y.md', 'o hai from bar/y')

    File.symlink('../bar', 'foo/barlink')

    expected_files = ['foo/barlink/y.md', 'foo/x.md']
    actual_files   = Nanoc::DataSources::Filesystem::Tools.all_files_in('foo', nil).sort

    assert_equal expected_files, actual_files
  end

  def test_all_files_in_follows_symlinks_to_files
    # Write sample files
    File.write('bar', 'o hai from bar')
    FileUtils.mkdir_p('dir')
    File.write('dir/foo', 'o hai from foo')
    File.symlink('../bar', 'dir/bar-link')

    # Check
    expected_files = ['dir/bar-link', 'dir/foo']
    actual_files   = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir', nil).sort

    assert_equal expected_files, actual_files
  end

  def test_resolve_symlink
    File.write('foo', 'o hai')
    File.symlink('foo', 'bar')
    File.symlink('bar', 'baz')
    File.symlink('baz', 'qux')

    expected = File.expand_path('foo')
    actual   = Nanoc::DataSources::Filesystem::Tools.resolve_symlink('qux')

    assert_equal expected, actual
  end

  def test_resolve_symlink_too_many
    File.write('foo', 'o hai')
    File.symlink('foo', 'symlin-0')
    (1..7).each do |i|
      File.symlink("symlink-#{i - 1}", "symlink-#{i}")
    end

    assert_raises Nanoc::DataSources::Filesystem::Tools::MaxSymlinkDepthExceededError do
      Nanoc::DataSources::Filesystem::Tools.resolve_symlink('symlink-7')
    end
  end

  def test_unwanted_dotfiles_not_found
    # Write sample files
    FileUtils.mkdir_p('dir')
    File.write('dir/.DS_Store', 'o hai')
    File.write('dir/.htaccess', 'o hai')

    actual_files = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir', nil).sort

    assert_equal [], actual_files
  end

  def test_user_dotfiles_are_valid_items
    # Write sample files
    FileUtils.mkdir_p('dir')
    File.write('dir/.other', 'o hai')

    actual_files = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir', '**/.other').sort

    assert_equal ['dir/.other'], actual_files
  end

  def test_multiple_user_dotfiles_are_valid_items
    # Write sample files
    FileUtils.mkdir_p('dir')
    File.write('dir/.other', 'o hai')
    File.write('dir/.DS_Store', 'o hai')

    actual_files = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir', ['**/.other', '**/.DS_Store']).sort

    assert_equal ['dir/.other', 'dir/.DS_Store'].sort, actual_files.sort
  end

  def test_extra_files_string_with_leading_slash
    # Write sample files
    FileUtils.mkdir_p('dir')
    File.write('dir/.other', 'o hai')
    File.write('dir/.DS_Store', 'o hai')

    actual_files = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir', '/**/.DS_Store').sort

    assert_equal ['dir/.DS_Store'].sort, actual_files.sort
  end

  def test_extra_files_array_with_leading_slash
    # Write sample files
    FileUtils.mkdir_p('dir')
    File.write('dir/.other', 'o hai')
    File.write('dir/.DS_Store', 'o hai')

    actual_files = Nanoc::DataSources::Filesystem::Tools.all_files_in('dir', ['/**/.DS_Store']).sort

    assert_equal ['dir/.DS_Store'].sort, actual_files.sort
  end

  def test_unknown_pattern
    # Write sample files
    FileUtils.mkdir_p('dir')
    File.write('dir/.other', 'o hai')

    pattern = { dotfiles: '**/.other' }

    assert_raises Nanoc::Core::TrivialError, "Do not know how to handle extra_files: #{pattern.inspect}" do
      Nanoc::DataSources::Filesystem::Tools.all_files_in('dir0', pattern)
    end
  end
end
