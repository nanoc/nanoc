# encoding: utf-8

class Nanoc::Filters::KramdownTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_filter
    if_have 'kramdown' do
      # Create filter
      filter = ::Nanoc::Filters::Kramdown.new

      # Run filter
      result = filter.run("This is _so_ **cool**!")
      assert_equal("<p>This is <em>so</em> <strong>cool</strong>!</p>\n", result)
    end
  end

end
