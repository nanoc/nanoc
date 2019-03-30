# frozen_string_literal: true

describe 'String#__nanoc_cleaned_identifier' do
  it 'does not convert already clean paths' do
    expect('/foo/bar/'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'prepends slash if necessary' do
    expect('foo/bar/'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'appends slash if necessary' do
    expect('/foo/bar'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'removes double slashes at start' do
    expect('//foo/bar/'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'removes double slashes at end' do
    expect('/foo/bar//'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end
end
