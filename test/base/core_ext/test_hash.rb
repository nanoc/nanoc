require 'test/helper'

class Nanoc::CoreExtHashTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

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

  def test_hash_clean_already_parsed_time
    hash         = { 'created_at' => Time.parse('12/07/2004') }
    hash_cleaned = { :created_at => Time.parse('12/07/2004') }
    assert_equal(hash_cleaned, hash.clean)
  end

  def test_hash_clean_already_parsed_date
    hash         = { 'created_on' => Date.parse('12/07/2004') }
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
    hash                        = { 'foo' => 'bar', :foo => 'bar', 3 => 'lol', nil => 'moo' }
    hash_with_stringified_keys  = { 'foo' => 'bar', 'foo' => 'bar', '3' => 'lol', '' => 'moo' }
    assert_equal(hash_with_stringified_keys, hash.stringify_keys)
  end

end
