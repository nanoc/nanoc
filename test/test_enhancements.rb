require 'test/unit'
require 'fileutils'
require 'time'

require File.dirname(__FILE__) + '/../lib/nanoc.rb'

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
    assert_raise SystemExit do
      [ ].ensure_single('moofs', 'blargh')
    end
    assert_raise SystemExit do
      [ 1, 2 ].ensure_single('moofs', 'blargh')
    end
    assert_nothing_raised do
      [ 1 ].ensure_single('moofs', 'blargh')
    end
  end

  def test_file_read
    assert_equal 'created_at: 12/07/04', File.read('test.yaml')
  end

  def test_yaml_load_file_and_clean
    assert_equal({ :created_at => Time.parse('12/07/04') }, YAML.load_file_and_clean('test.yaml'))
  end

  def test_hash_clean
    hash1         = { 'foo' => 'bar' }
    hash1_cleaned = { :foo => 'bar' }

    hash2         = { 'created_at' => '12/07/2004' }
    hash2_cleaned = { :created_at => Time.parse('12/07/2004') }

    assert_equal hash1_cleaned, hash1.clean
    assert_equal hash2_cleaned, hash2.clean
  end

  def test_string_filter
    text = '<%= @foo %>'
    context = { :foo => 'Te\'st' }

    assert_equal 'Te\'st', text.filter([ 'eruby' ], :eruby_context => context)

    begin
      assert_equal '<p>Te&#8217;st</p>', text.filter([ 'eruby', 'markdown', 'smartypants' ], :eruby_context => context)
    rescue NameError
      $stderr.puts 'WARNING: Unable to test String#filter! (BlueCloth or RubyPants not installed)'
    end
  end

  def test_string_markdown
    begin
      assert_equal 'Hello!'.markdown, '<p>Hello!</p>'
    rescue NameError
      $stderr.puts 'WARNING: Unable to test String#markdown (BlueCloth not installed)'
    end
  end

  def test_string_smartypants
    begin
      assert_equal 'Te\'st'.smartypants, 'Te&#8217;st'
    rescue NameError
      $stderr.puts 'WARNING: Unable to test String#smartypants (RubyPants not installed)'
    end
  end

  def test_string_eruby
    assert_equal '<%= "moo" %>'.eruby, 'moo'
    assert_equal '<%= @foo %>'.eruby(:foo => 'bar'), 'bar'
  end

  def test_filemanager_create_dir
    FileManager.create_dir 'tmp' do
      FileManager.create_dir 'foo'
    end

    assert File.exist?('tmp')
    assert File.directory?('tmp')

    assert File.exist?('tmp/foo')
    assert File.directory?('tmp/foo')

    assert !File.exist?('foo')
  end

  def test_filemanager_create_file
    FileManager.create_dir 'tmp' do
      FileManager.create_file 'bar' do
        "asdf"
      end
    end

    assert File.exist?('tmp/bar')
    assert File.file?('tmp/bar')
    assert_equal 'asdf', File.read('tmp/bar')
  end
end
