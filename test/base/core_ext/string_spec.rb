# encoding: utf-8

describe 'String#checksum' do

  it 'should work on empty strings' do
    ''.checksum.must_equal 'PfY7essFItpoXa1f6EuB/deyUmQ='
  end

  it 'should work on all strings' do
    'abc'.checksum.must_equal 'NkkYRO+25f6psNSeCYykXKCg3C0='
  end

end
