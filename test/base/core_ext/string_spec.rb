# encoding: utf-8

describe 'String#cleaned_identifier' do

  it 'should not convert already clean paths' do
    '/foo/bar/'.cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should prepend slash if necessary' do
    'foo/bar/'.cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should append slash if necessary' do
    '/foo/bar'.cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should remove double slashes at start' do
    '//foo/bar/'.cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should remove double slashes at end' do
    '/foo/bar//'.cleaned_identifier.must_equal '/foo/bar/'
  end

end

describe 'String#checksum' do

  it 'should work on empty strings' do
    ''.checksum.must_equal 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
  end

  it 'should work on all strings' do
    'abc'.checksum.must_equal 'a9993e364706816aba3e25717850c26c9cd0d89d'
  end

end
