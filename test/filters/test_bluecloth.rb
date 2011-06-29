# encoding: utf-8

class Nanoc::Filters::BlueClothTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'bluecloth' do
      # Create filter
      filter = ::Nanoc::Filters::BlueCloth.new

      # Run filter
      result = filter.run("> Quote")
      assert_match %r{<blockquote>\s*<p>Quote</p>\s*</blockquote>}, result
    end
  end

end
