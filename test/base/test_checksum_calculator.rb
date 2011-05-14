# encoding: utf-8

require 'test/helper'

class Nanoc3::ChecksumCalculatorTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_calculate
    calculator = Nanoc3::ChecksumCalculator.new
    obj = Nanoc3::Item.new('Moo?', {}, '/animals/cow/')
    new_checksum = 'Moo?'.checksum + '-' + {}.checksum
    assert_equal new_checksum, calculator[obj]
  end

end
