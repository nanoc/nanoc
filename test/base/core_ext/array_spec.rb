# encoding: utf-8

require 'test/helper'

describe 'Array#symbolize_keys' do

  it 'should convert keys to symbols' do
    array_old = [ 'xyz', { 'foo' => 'bar' } ]
    array_new = [ 'xyz', { :foo  => 'bar' } ]
    array_old.symbolize_keys.must_equal array_new
  end

end

describe 'Hash#stringify_keys' do

  it 'should convert keys to strings' do
    array_old = [ 'xyz', { :foo  => 'bar' } ]
    array_new = [ 'xyz', { 'foo' => 'bar' } ]
    array_old.symbolize_keys.must_equal array_new
  end

end
