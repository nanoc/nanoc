# frozen_string_literal: true

describe 'Array#__nanoc_symbolize_keys_recursively' do
  it 'should convert keys to symbols' do
    array_old = [:abc, 'xyz', { 'foo' => 'bar', :baz => :qux }]
    array_new = [:abc, 'xyz', { foo: 'bar', baz: :qux }]
    expect(array_old.__nanoc_symbolize_keys_recursively).to eql(array_new)
  end
end

describe 'Array#__nanoc_freeze_recursively' do
  it 'should prevent first-level elements from being modified' do
    array = [:a, %i[b c], :d]
    array.__nanoc_freeze_recursively

    expect { array[0] = 123 }.to raise_frozen_error
  end

  it 'should prevent second-level elements from being modified' do
    array = [:a, %i[b c], :d]
    array.__nanoc_freeze_recursively

    expect { array[1][0] = 123 }.to raise_frozen_error
  end

  it 'should not freeze infinitely' do
    a = []
    a << a

    a.__nanoc_freeze_recursively

    expect(a).to be_frozen
    expect(a[0]).to be_frozen
  end
end
