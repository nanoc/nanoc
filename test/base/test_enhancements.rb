require 'helper'

class EnhancementsTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_nanoc_require
    assert_raise(SystemExit) { nanoc_require 'askjdfdsldjlfksljakfjlkdsasd' }
  end

  def test_filemanager_create_dir
    FileManager.create_dir 'tmp'

    assert(File.exist?('tmp'))
    assert(File.directory?('tmp'))
  end

  def test_filemanager_create_file
    FileManager.create_dir 'tmp'
    FileManager.create_file 'tmp/bar' do
      "asdf"
    end

    assert(File.exist?('tmp/bar'))
    assert(File.file?('tmp/bar'))
    assert_equal('asdf', File.read('tmp/bar'))
  end

end
