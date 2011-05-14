# encoding: utf-8

require 'test/helper'

describe 'Pathname#checksum' do

  it 'should work on empty files' do
    File.open('myfile', 'w') { |io| io.write('') }
    pathname = Pathname.new('myfile')
    pathname.checksum.must_equal 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
  end

  it 'should work on all files' do
    File.open('myfile', 'w') { |io| io.write('abc') }
    pathname = Pathname.new('myfile')
    pathname.checksum.must_equal 'a9993e364706816aba3e25717850c26c9cd0d89d'
  end

end
