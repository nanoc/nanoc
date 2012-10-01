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

describe 'String#slug' do

  it 'should work on empty strings' do
    ''.slug.must_equal ''
  end

  it 'should remove single quotes' do
    "don'tdon't".slug.must_equal 'dontdont'
  end

  it 'should remove double quotes' do
    'a"b"c'.slug.must_equal 'abc'
  end

  it 'should transform uppercase A-Z to lowercase a-z' do
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.slug.must_equal 'abcdefghijklmnopqrstuvwxyz'
  end

  it 'should replace sequences of non-alphanumerics with a single - and then remove any leading or trailing -' do
    ',.[;abc!@#$%^&*(123{}":>?:"{'.slug.must_equal 'abc-123'
  end

end
