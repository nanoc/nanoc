require 'test/unit'

require File.dirname(__FILE__) + '/../lib/nanoc.rb'

class CompileTest < Test::Unit::TestCase
  def setup
    $quiet = true
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.rm_rf 'tmp'
    $quiet = false
  end

  def test_compile
    # Prepare
    FileUtils.cd('tmp')
    Nanoc::Creator.create_site('site')
    FileUtils.cd('site')
    
    # Test empty site
    Nanoc::Compiler.new.run
    assert File.file?('output/index.html')
    assert !File.file?('output/moo/index.html')
    
    # Test new page
    Nanoc::Creator.create_page('moo')
    Nanoc::Compiler.new.run
    assert File.file?('output/index.html')
    assert File.file?('output/moo/index.html')
    
    # Unprepare
    FileUtils.cd('..')
    FileUtils.cd('..')
  end
end
