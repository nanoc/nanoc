# encoding: utf-8

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

describe 'Hash#freeze_recursively' do

  it 'should prevent first-level elements from being modified' do
    hash = { :a => { :b => :c } }
    hash.freeze_recursively

    raised = false
    begin
      hash[:a] = 123
    rescue => e
      raised = true
      assert_match /^can't modify frozen /, e.message
    end
    assert raised
  end

  it 'should prevent second-level elements from being modified' do
    hash = { :a => { :b => :c } }
    hash.freeze_recursively

    raised = false
    begin
      hash[:a][:b] = 123
    rescue => e
      raised = true
      assert_match /^can't modify frozen /, e.message
    end
    assert raised
  end

end

describe 'Hash#checksum' do

  it 'should work' do
    expectation = 'fec9ae7163e8b8d57a15d51821d2c68d4a6bb169'
    { :foo => 123 }.checksum.must_equal expectation
  end

end
