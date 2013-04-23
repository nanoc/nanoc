# encoding: utf-8

describe 'String#checksum' do

  it 'should work on empty strings' do
    ''.checksum.must_equal 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
  end

  it 'should work on all strings' do
    'abc'.checksum.must_equal 'a9993e364706816aba3e25717850c26c9cd0d89d'
  end

end
