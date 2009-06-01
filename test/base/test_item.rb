# encoding: utf-8

require 'test/helper'

class Nanoc3::ItemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_content
    # TODO implement
  end

  def test_lookup
    # Create item and rep
    item = Nanoc3::Item.new(
      "content",
      { :one => 'one in item' },
      '/path/'
    )

    # Test finding one
    assert_equal('one in item', item[:one])

    # Test finding two
    assert_equal(nil, item[:two])
  end

end
