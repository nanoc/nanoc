# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::LessTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'less' do
      # Create filter
      filter = ::Nanoc3::Filters::Less.new

      # Run filter
      result = filter.run('.foo { bar: 1 + 1 }')
      assert_match /\.foo\s*\{\s*bar:\s*2;?\s*\}/, result
    end
  end

end
