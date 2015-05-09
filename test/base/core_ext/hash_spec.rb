# encoding: utf-8

describe 'Hash#__nanoc_symbolize_keys_recursively' do
  it 'should convert keys to symbols' do
    hash_old = { 'foo' => 'bar' }
    hash_new = { foo: 'bar' }
    hash_old.__nanoc_symbolize_keys_recursively.must_equal hash_new
  end

  it 'should not require string keys' do
    hash_old = { Time.now => 'abc' }
    hash_new = hash_old
    hash_old.__nanoc_symbolize_keys_recursively.must_equal hash_new
  end
end

describe 'Hash#__nanoc_stringify_keys_recursively' do
  it 'should leave strings as strings' do
    hash_old = { 'foo' => 'bar' }
    hash_new = { 'foo' => 'bar' }
    hash_old.__nanoc_stringify_keys_recursively.must_equal hash_new
  end

  it 'should convert symbols to strings' do
    hash_old = { foo: 'bar' }
    hash_new = { 'foo' => 'bar' }
    hash_old.__nanoc_stringify_keys_recursively.must_equal hash_new
  end

  it 'should convert integers to strings' do
    hash_old = { 123   => 'bar' }
    hash_new = { '123' => 'bar' }
    hash_old.__nanoc_stringify_keys_recursively.must_equal hash_new
  end

  it 'should convert nil to an empty string' do
    hash_old = { nil => 'bar' }
    hash_new = { ''  => 'bar' }
    hash_old.__nanoc_stringify_keys_recursively.must_equal hash_new
  end
end

describe 'Hash#__nanoc_freeze_recursively' do
  include Nanoc::TestHelpers

  it 'should prevent first-level elements from being modified' do
    hash = { a: { b: :c } }
    hash.__nanoc_freeze_recursively

    assert_raises_frozen_error do
      hash[:a] = 123
    end
  end

  it 'should prevent second-level elements from being modified' do
    hash = { a: { b: :c } }
    hash.__nanoc_freeze_recursively

    assert_raises_frozen_error do
      hash[:a][:b] = 123
    end
  end

  it 'should not freeze infinitely' do
    a = {}
    a[:x] = a

    a.__nanoc_freeze_recursively

    assert a.frozen?
    assert a[:x].frozen?
    assert_equal a, a[:x]
  end
end

describe 'Hash#__nanoc_checksum' do
  it 'should work' do
    expectation = 'wy7gHokc700tqJ/BmJ+EK6/F0bc='
    { foo: 123 }.__nanoc_checksum.must_equal expectation
  end

  it 'should not sort keys' do
    a = { a: 1, c: 2, b: 3 }.__nanoc_checksum
    b = { a: 1, b: 3, c: 2 }.__nanoc_checksum
    a.wont_equal b
  end
end
