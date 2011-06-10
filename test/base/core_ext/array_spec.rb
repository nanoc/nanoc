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
      assert_match /^can't modify frozen /, e.message
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
      assert_match /^can't modify frozen /, e.message
    end
    assert raised
  end

end
