require 'test/helper'

describe 'String#cleaned_path' do

  before { global_setup    }
  after  { global_teardown }

  it 'should not convert already clean paths' do
    '/foo/bar/'.cleaned_path.should == '/foo/bar/'
  end

  it 'should prepend slash if necessary' do
    'foo/bar/'.cleaned_path.should == '/foo/bar/'
  end

  it 'should append slash if necessary' do
    '/foo/bar'.cleaned_path.should == '/foo/bar/'
  end

  it 'should remove double slashes at start' do
    '//foo/bar/'.cleaned_path.should == '/foo/bar/'
  end

  it 'should remove double slashes at end' do
    '/foo/bar//'.cleaned_path.should == '/foo/bar/'
  end

end
