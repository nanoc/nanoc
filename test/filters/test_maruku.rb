# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::MarukuTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'maruku' do
      # Create filter
      filter = ::Nanoc3::Filters::Maruku.new

      # Run filter
      result = filter.run("This is _so_ *cool*!")
      assert_equal("<p>This is <em>so</em> <em>cool</em>!</p>", result)
    end
  end

end
