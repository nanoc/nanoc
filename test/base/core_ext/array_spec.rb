# encoding: utf-8

describe 'Array#symbolize_keys_recursively' do

  it 'should convert keys to symbols' do
    array_old = [ :abc, 'xyz', { 'foo' => 'bar', :baz => :qux } ]
    array_new = [ :abc, 'xyz', { :foo  => 'bar', :baz => :qux } ]
    array_old.symbolize_keys_recursively.must_equal array_new
  end

end

describe 'Array#stringify_keys_recursively' do

  it 'should convert keys to strings' do
    array_old = [ :abc, 'xyz', { :foo  => 'bar', 'baz' => :qux } ]
    array_new = [ :abc, 'xyz', { 'foo' => 'bar', 'baz' => :qux } ]
    array_old.stringify_keys_recursively.must_equal array_new
  end

end

describe 'Array#freeze_recursively' do

  include Nanoc::TestHelpers

  it 'should prevent first-level elements from being modified' do
    array = [ :a, [ :b, :c ], :d ]
    array.freeze_recursively

    assert_raises_frozen_error do
      array[0] = 123
    end
  end

  it 'should prevent second-level elements from being modified' do
    array = [ :a, [ :b, :c ], :d ]
    array.freeze_recursively

    assert_raises_frozen_error do
      array[1][0] = 123
    end
  end

  it 'should not freeze infinitely' do
    a = []
    a << a

    a.freeze_recursively

    assert a.frozen?
    assert a[0].frozen?
    assert_equal a, a[0]
  end

end

describe 'Array#checksum' do

  it 'should work' do
    expectation = 'CEUlNvu/3DUmlbtpFRiLHU8oHA0='
    [ [ :foo, 123 ] ].checksum.must_equal expectation
  end

end
