require 'test/unit'

require File.dirname(__FILE__) + '/../lib/nanoc/file_management.rb'

class FileManagementTest < Test::Unit::TestCase
  def teardown
    FileUtils.rm_rf 'tmp'
  end
  
  def test_create_dir
    create_dir 'tmp' do
      create_dir 'foo'
    end
    
    assert File.exist?('tmp')
    assert File.directory?('tmp')
    
    assert File.exist?('tmp/foo')
    assert File.directory?('tmp/foo')
    
    assert !File.exist?('foo')
  end
  
  def test_create_file
    create_dir 'tmp' do
      create_file 'bar' do
        "asdf"
      end
    end
    
    assert File.exist?('tmp/bar')
    assert File.file?('tmp/bar')
    assert_equal 'asdf', File.read_file('tmp/bar')
  end
end
