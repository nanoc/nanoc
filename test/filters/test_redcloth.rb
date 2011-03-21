# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::RedClothTest < Nanoc3::TestCase

  def test_filter
    if_have 'redcloth' do
      # Get filter
      filter = ::Nanoc3::Filters::RedCloth.new

      # Run filter
      result = filter.run("h1. Foo")
      assert_equal("<h1>Foo</h1>", result)
    end
  end

  def test_filter_with_options
    if_have 'redcloth' do
      # Get filter
      filter = ::Nanoc3::Filters::RedCloth.new

      # Run filter without options
      result = filter.run("I am a member of SPECTRE.")
      assert_equal("<p>I am a member of <span class=\"caps\">SPECTRE</span>.</p>", result)

      # Run filter with options
      result = filter.run("I am a member of SPECTRE.", :no_span_caps => true)
      assert_equal("<p>I am a member of SPECTRE.</p>", result)
    end
  end

end
