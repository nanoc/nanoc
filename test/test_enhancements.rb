require 'test/unit'

require File.join(File.dirname(__FILE__), 'helper.rb')

class EnhancementsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_nanoc_require
    assert_raise(SystemExit) { nanoc_require 'askjdfdsldjlfksljakfjlkdsasd' }
  end

  def test_filemanager_create_dir_without_block
    FileManager.create_dir 'tmp'

    assert(File.exist?('tmp'))
    assert(File.directory?('tmp'))
  end

  def test_filemanager_create_dir_with_block
    FileManager.create_dir 'tmp' do
      FileManager.create_dir 'foo'
    end

    assert(File.exist?('tmp'))
    assert(File.directory?('tmp'))

    assert(File.exist?('tmp/foo'))
    assert(File.directory?('tmp/foo'))

    assert(!File.exist?('foo'))
  end

  def test_filemanager_create_file
    FileManager.create_dir 'tmp' do
      FileManager.create_file 'bar' do
        "asdf"
      end
    end

    assert(File.exist?('tmp/bar'))
    assert(File.file?('tmp/bar'))
    assert_equal('asdf', File.read('tmp/bar'))
  end

end
