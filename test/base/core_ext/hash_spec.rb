# frozen_string_literal: true

require 'helper'

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
