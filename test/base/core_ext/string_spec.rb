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
    ''.checksum.must_equal '3df63b7acb0522da685dad5fe84b81fdd7b25264'
  end

  it 'should work on all strings' do
    'abc'.checksum.must_equal '36491844efb6e5fea9b0d49e098ca45ca0a0dc2d'
  end

end
