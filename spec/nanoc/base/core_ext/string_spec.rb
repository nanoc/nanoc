# frozen_string_literal: true

describe 'String#__nanoc_cleaned_identifier' do
  it 'should not convert already clean paths' do
    expect('/foo/bar/'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'should prepend slash if necessary' do
    expect('foo/bar/'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'should append slash if necessary' do
    expect('/foo/bar'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'should remove double slashes at start' do
    expect('//foo/bar/'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end

  it 'should remove double slashes at end' do
    expect('/foo/bar//'.__nanoc_cleaned_identifier).to eql('/foo/bar/')
  end
end
