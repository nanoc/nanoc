# frozen_string_literal: true

describe 'Hash#__nanoc_symbolize_keys_recursively' do
  it 'converts keys to symbols' do
    hash_old = { 'foo' => 'bar' }
    hash_new = { foo: 'bar' }
    expect(hash_old.__nanoc_symbolize_keys_recursively).to eql(hash_new)
  end

  it 'does not require string keys' do
    hash_old = { Time.now => 'abc' }
    hash_new = hash_old
    expect(hash_old.__nanoc_symbolize_keys_recursively).to eql(hash_new)
  end
end

describe 'Hash#__nanoc_stringify_keys_recursively' do
  it 'converts keys to strings' do
    hash_old = { foo: 'bar' }
    hash_new = { 'foo' => 'bar' }
    expect(hash_old.__nanoc_stringify_keys_recursively).to eql(hash_new)
  end

  it 'does not require symbol keys' do
    hash_old = { Time.now => 'abc' }
    hash_new = hash_old
    expect(hash_old.__nanoc_stringify_keys_recursively).to eql(hash_new)
  end
end

describe 'Hash#__nanoc_freeze_recursively' do
  it 'prevents first-level elements from being modified' do
    hash = { a: { b: :c } }
    hash.__nanoc_freeze_recursively

    expect { hash[:a] = 123 }.to raise_frozen_error
  end

  it 'prevents second-level elements from being modified' do
    hash = { a: { b: :c } }
    hash.__nanoc_freeze_recursively

    expect { hash[:a][:b] = 123 }.to raise_frozen_error
  end

  it 'does not freeze infinitely' do
    a = {}
    a[:x] = a

    a.__nanoc_freeze_recursively

    expect(a).to be_frozen
    expect(a[0]).to be_frozen
  end
end
