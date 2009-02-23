require 'test/helper'

class Nanoc::Filters::BlueClothTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    if_have 'bluecloth' do
      # Create filter
      filter = ::Nanoc::Filters::BlueCloth.new

      # Run filter
      result = filter.run("> Quote")
      assert_equal("<blockquote>\n    <p>Quote</p>\n</blockquote>", result)
    end
  end

end
