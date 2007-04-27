require 'test/unit'
require 'fileutils'
require 'time'

require File.dirname(__FILE__) + '/../lib/nanoc/enhancements.rb'

class EnhancementsTest < Test::Unit::TestCase
  def setup
    open('test.yaml', 'w') do |io|
      io.write('created_at: 12/07/04')
    end
  end
  
  def teardown
    FileUtils.rm('test.yaml')
  end
  
  def test_array_ensure_single
    assert_raise RuntimeError do
      [ ].ensure_single('moofs', 'blargh')
    end
    assert_raise RuntimeError do
      [ 1, 2 ].ensure_single('moofs', 'blargh')
    end
    assert_nothing_raised do
      [ 1 ].ensure_single('moofs', 'blargh')
    end
  end
  
  def test_file_read_file
    assert_equal 'created_at: 12/07/04', File.read_file('test.yaml')
  end
  
  def test_file_read_yaml
    assert_equal({ 'created_at' => '12/07/04' }, File.read_yaml('test.yaml'))
  end
  
  def test_file_read_clean_yaml
    assert_equal({ :created_at => Time.parse('12/07/04') }, File.read_clean_yaml('test.yaml'))
  end
  
  def test_hash_clean
    hash1         = { 'foo' => 'bar' }
    hash1_cleaned = { :foo => 'bar' }
    
    hash2         = { 'created_at' => '12/07/2004' }
    hash2_cleaned = { :created_at => Time.parse('12/07/2004') }
    
    assert_equal hash1_cleaned, hash1.clean
    assert_equal hash2_cleaned, hash2.clean
  end
  
  def test_string_filter!
    text = '<%= @foo %>'
    context = { :foo => 'Te\'st' }
    
    text.filter!([ 'eruby' ], :eruby_context => context)
    assert_equal 'Te\'st', text
    
    text.filter!([ 'markdown', 'rubypants' ])
    assert_equal '<p>Te&#8217;st</p>', text
  end
  
  def test_string_markdown
    assert_equal 'Hello!'.markdown, '<p>Hello!</p>'
  end
  
  def test_string_rubypants
    assert_equal 'Te\'st'.rubypants, 'Te&#8217;st'
  end
  
  def test_string_eruby
    assert_equal '<%= "moo" %>'.eruby, 'moo'
    assert_equal '<%= @foo %>'.eruby(:foo => 'bar'), 'bar'
  end
end
