# frozen_string_literal: true

require 'helper'

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
