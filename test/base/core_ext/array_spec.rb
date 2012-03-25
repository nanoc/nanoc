# encoding: utf-8

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

describe 'Array#freeze_recursively' do

  it 'should prevent first-level elements from being modified' do
    array = [ :a, [ :b, :c ], :d ]
    array.freeze_recursively

    raised = false
    begin
      array[0] = 123
    rescue => e
      raised = true
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised
  end

  it 'should prevent second-level elements from being modified' do
    array = [ :a, [ :b, :c ], :d ]
    array.freeze_recursively

    raised = false
    begin
      array[1][0] = 123
    rescue => e
      raised = true
      assert_match /(^can't modify frozen |^unable to modify frozen object$)/, e.message
    end
    assert raised
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
    expectation = '78468f950645150238a26f5b8f2dde39a75a7028'
    [ [ :foo, 123 ]].checksum.must_equal expectation
  end

end
