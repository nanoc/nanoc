describe 'String#__nanoc_cleaned_identifier' do
  it 'should not convert already clean paths' do
    '/foo/bar/'.__nanoc_cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should prepend slash if necessary' do
    'foo/bar/'.__nanoc_cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should append slash if necessary' do
    '/foo/bar'.__nanoc_cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should remove double slashes at start' do
    '//foo/bar/'.__nanoc_cleaned_identifier.must_equal '/foo/bar/'
  end

  it 'should remove double slashes at end' do
    '/foo/bar//'.__nanoc_cleaned_identifier.must_equal '/foo/bar/'
  end
end

describe 'String#__nanoc_checksum' do
  it 'should work on empty strings' do
    ''.__nanoc_checksum.must_equal 'PfY7essFItpoXa1f6EuB/deyUmQ='
  end

  it 'should work on all strings' do
    'abc'.__nanoc_checksum.must_equal 'NkkYRO+25f6psNSeCYykXKCg3C0='
  end
end
