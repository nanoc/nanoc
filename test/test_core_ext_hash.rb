require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CoreExtHashTest < Test::Unit::TestCase

  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
  end

  def teardown
    $quiet = false
  end

  def test_hash_clean_simple
    hash         = { 'foo' => 'bar' }
    hash_cleaned = { :foo => 'bar' }
    assert_equal(hash_cleaned, hash.clean)
  end

  def test_hash_clean_time
    hash         = { 'created_at' => '12/07/2004' }
    hash_cleaned = { :created_at => Time.parse('12/07/2004') }
    assert_equal(hash_cleaned, hash.clean)
  end

  def test_hash_clean_date
    hash         = { 'created_on' => '12/07/2004' }
    hash_cleaned = { :created_on => Date.parse('12/07/2004') }
    assert_equal(hash_cleaned, hash.clean)
  end

  def test_hash_clean_boolean
    hash         = { 'foo' => 'true', 'bar' => 'false' }
    hash_cleaned = { :foo => true, :bar => false }
    assert_equal(hash_cleaned, hash.clean)
  end

  def test_hash_clean_nil
    hash         = { 'foo' => 'nil', 'bar' => 'none' }
    hash_cleaned = { :foo => 'nil', :bar => nil }
    assert_equal(hash_cleaned, hash.clean)
  end

  def test_hash_stringify_keys
    hash                        = { :foo => 'bar', 'baz' => :quux, :x => { :y => :z } }
    hash_with_stringified_keys  = { 'foo' => 'bar', 'baz' => :quux, 'x' => { 'y' => :z } }
    assert_equal(hash_with_stringified_keys, hash.stringify_keys)
  end

end
