# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::KramdownTest < Nanoc3::TestCase

  def test_filter
    if_have 'kramdown' do
      # Create filter
      filter = ::Nanoc3::Filters::Kramdown.new

      # Run filter
      result = filter.run("This is _so_ **cool**!")
      assert_equal("<p>This is <em>so</em> <strong>cool</strong>!</p>\n", result)
    end
  end

end
