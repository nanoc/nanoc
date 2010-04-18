# encoding: utf-8

require 'test/helper'

class Nanoc3::ChecksummerTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_checksum_for_file
    # Create files
    File.open('one', 'w') { |io| io.write('abc') }
    File.open('two', 'w') { |io| io.write('abcdefghijklmnopqrstuvwxyz') }

    # Check
    assert_equal 'a9993e364706816aba3e25717850c26c9cd0d89d',
      Nanoc3::Checksummer.checksum_for_file('one')
    assert_equal '32d10c7b8cf96570ca04ce37f2a19d84240d3a89',
      Nanoc3::Checksummer.checksum_for_file('two')
  end

  def test_checksum_for_string
    # Check
    assert_equal 'a9993e364706816aba3e25717850c26c9cd0d89d',
      Nanoc3::Checksummer.checksum_for_string('abc')
    assert_equal '32d10c7b8cf96570ca04ce37f2a19d84240d3a89',
      Nanoc3::Checksummer.checksum_for_string('abcdefghijklmnopqrstuvwxyz')
  end

end
