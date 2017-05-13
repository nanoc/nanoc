# frozen_string_literal: true

require 'helper'

describe 'Array#__nanoc_symbolize_keys_recursively' do
  it 'should convert keys to symbols' do
    array_old = [:abc, 'xyz', { 'foo' => 'bar', :baz => :qux }]
    array_new = [:abc, 'xyz', { foo: 'bar', baz: :qux }]
    array_old.__nanoc_symbolize_keys_recursively.must_equal array_new
  end
end

describe 'Array#__nanoc_freeze_recursively' do
  include Nanoc::TestHelpers

  it 'should prevent first-level elements from being modified' do
    array = [:a, %i[b c], :d]
    array.__nanoc_freeze_recursively

    assert_raises_frozen_error do
      array[0] = 123
    end
  end

  it 'should prevent second-level elements from being modified' do
    array = [:a, %i[b c], :d]
    array.__nanoc_freeze_recursively

    assert_raises_frozen_error do
      array[1][0] = 123
    end
  end

  it 'should not freeze infinitely' do
    a = []
    a << a

    a.__nanoc_freeze_recursively

    assert a.frozen?
    assert a[0].frozen?
    assert_equal a, a[0]
  end
end
