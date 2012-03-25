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
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
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
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised
  end

  it 'should not freeze infinitely' do
    a = {}
    a[:x] = a

    a.freeze_recursively

    assert a.frozen?
    assert a[:x].frozen?
    assert_equal a, a[:x]
  end

end

describe 'Hash#checksum' do

  it 'should work' do
    expectation = '78468f950645150238a26f5b8f2dde39a75a7028'
    { :foo => 123 }.checksum.must_equal expectation
    [ [ :foo, 123 ]].checksum.must_equal expectation
  end

  it 'should sort keys' do
    a = { :a => 1, :c => 2, :b => 3 }.checksum
    b = { :a => 1, :b => 3, :c => 2 }.checksum
    a.must_equal b
  end

end
