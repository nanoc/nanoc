require 'test/helper'

describe 'Hash#symbolize_keys' do

  it 'should convert keys to symbols' do
    hash_old = { 'foo' => 'bar' }
    hash_new = { :foo  => 'bar' }
    hash_old.symbolize_keys.must_equal hash_new
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
