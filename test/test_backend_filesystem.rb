require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class FilesystemBackendTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp' if File.exist?('tmp')
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f if File.exist?(f)}
    $quiet = false
  end

  def test_compile_site_with_file_object
    with_site_fixture 'site_with_file_object' do |site|
      assert_nothing_raised() { site.compile }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert(File.read('output/index.html').include?("This page was last modified at #{File.new('content/content.erb').mtime}."))
    end
  end

end
