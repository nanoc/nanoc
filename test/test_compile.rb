require 'test/unit'

require File.dirname(__FILE__) + '/../lib/nanoc/compile.rb'

class CompileTest < Test::Unit::TestCase
  def setup
    FileManager.create_dir 'tmp'
  end
  
  def teardown
    FileUtils.rm_rf 'tmp'
  end
  
  def test_compile
    FileUtils.cd('tmp')
    Nanoc.create_site('site')
    FileUtils.cd('site')
    Nanoc.create_page('moo')
    Nanoc.compile
    FileUtils.cd('..')
    FileUtils.cd('..')
    
    assert File.file?('tmp/site/output/index.html')
    assert File.file?('tmp/site/output/moo/index.html')
  end
end
