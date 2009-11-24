# encoding: utf-8

require 'test/helper'

describe 'Array#symbolize_keys' do

  it 'should convert keys to symbols' do
    array_old = [ :abc, 'xyz', { 'foo' => 'bar', :baz => :qux } ]
    array_new = [ :abc, 'xyz', { :foo  => 'bar', :baz => :qux } ]
    array_old.symbolize_keys.must_equal array_new
  end

end

describe 'Array#stringify_keys' do

  it 'should convert keys to strings' do
    array_old = [ :abc, 'xyz', { :foo  => 'bar', 'baz' => :qux } ]
    array_new = [ :abc, 'xyz', { 'foo' => 'bar', 'baz' => :qux } ]
    array_old.stringify_keys.must_equal array_new
  end

end
