require 'test/helper'

describe 'Hash#clean' do

  it 'should convert keys to symbols' do
    hash_old = { 'foo' => 'bar' }
    hash_new = { :foo  => 'bar' }
    hash_old.clean.must_equal hash_new
  end

  it 'should convert dates' do
    hash_old = { 'created_on' => '12/07/2004' }
    hash_new = { :created_on  => Date.parse('12/07/2004') }
    hash_old.clean.must_equal hash_new
  end

  it 'should convert times' do
    hash_old = { 'created_at' => '12/07/2004' }
    hash_new = { :created_at  => Time.parse('12/07/2004') }
    hash_old.clean.must_equal hash_new
  end

  it 'should not re-convert already parsed dates' do
    hash_old = { :created_on => Date.parse('12/07/2004') }
    hash_new = { :created_on => Date.parse('12/07/2004') }
    hash_old.clean.must_equal hash_new
  end

  it 'should not re-convert already parsed times' do
    hash_old = { :created_at => Time.parse('12/07/2004') }
    hash_new = { :created_at => Time.parse('12/07/2004') }
    hash_old.clean.must_equal hash_new
  end

  it 'should convert booleans' do
    hash_old = { :foo => 'true', :bar => 'false' }
    hash_new = { :foo => true, :bar => false }
    hash_old.clean.must_equal hash_new
  end

  it 'should convert "none" to nil' do
    hash_old = { :foo => 'none' }
    hash_new = { :foo => nil }
    hash_old.clean.must_equal hash_new
  end

  it 'should not convert "nil" to nil' do
    hash_old = { :foo => 'nil' }
    hash_new = { :foo => 'nil' }
    hash_old.clean.must_equal hash_new
  end

end

describe 'Hash#stringify_keys' do

  it 'should leave strings as strings' do
    hash_old = { 'foo' => 'bar' }
    hash_new = { 'foo' => 'bar' }
    hash_old.stringify_keys.must_equal hash_new
  end

  it 'should convert symbols to strings' do
    hash_old = { :foo  => 'bar' }
    hash_new = { 'foo' => 'bar' }
    hash_old.stringify_keys.must_equal hash_new
  end

  it 'should convert integers to strings' do
    hash_old = { 123   => 'bar' }
    hash_new = { '123' => 'bar' }
    hash_old.stringify_keys.must_equal hash_new
  end

  it 'should convert nil to an empty string' do
    hash_old = { nil => 'bar' }
    hash_new = { ''  => 'bar' }
    hash_old.stringify_keys.must_equal hash_new
  end

end
