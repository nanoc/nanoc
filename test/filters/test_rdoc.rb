# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::RDocTest < Nanoc3::TestCase

  def test_filter
    # Get filter
    filter = ::Nanoc3::Filters::RDoc.new

    # Run filter
    result = filter.run("= Foo")
    assert_match(%r{<h1>Foo</h1>\Z}, result)
  end

end
